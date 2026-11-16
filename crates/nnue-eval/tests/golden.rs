//! nnue-eval scores positions exactly as the engine's own nnue-eval does.
//!
//! The expected values were printed by the engine repository's `nnue-eval` at
//! v0.54.0 (`braveheart-tools`, commit 3fd0223) for its embedded net,
//! `net8x160-l050-r43390801430` (SHA-256 8ea67605…d556c), the code this binary
//! was moved from. A change here means a net would be checked against a
//! different evaluation: moving the engine pin is the usual reason, and then
//! the PR says so and updates the values.

use std::path::PathBuf;
use std::process::Command;

use braveheart_search::nnue::NETS;

/// (centipawns for the side to move, position), from the engine's nnue-eval.
const EXPECTED: [(i32, &str); 8] = [
    (
        85,
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    ),
    (
        -11,
        "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1",
    ),
    (
        91,
        "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3",
    ),
    (
        241,
        "r1bq1rk1/pp2bppp/2n1pn2/3p4/2PP4/2N1PN2/PP3PPP/R1BQKB1R w KQ - 0 8",
    ),
    (
        -252,
        "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
    ),
    (94, "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"),
    (250, "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1"),
    (-1560, "6k1/5ppp/8/8/8/8/5PPP/3R2K1 b - - 0 1"),
];

/// A scratch directory holding the engine's embedded net as a file.
fn scratch(name: &str) -> (PathBuf, PathBuf) {
    let dir = std::env::temp_dir().join(format!("nnue-eval-{name}-{}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    let net = NETS.last().expect("an embedded net");
    assert_eq!(net.id, "net8x160-l050-r43390801430", "the engine pin moved");
    let path = dir.join(format!("{}.nnue", net.id));
    std::fs::write(&path, net.file_bytes()).unwrap();
    (dir, path)
}

fn nnue_eval(args: &[&str]) -> std::process::Output {
    Command::new(env!("CARGO_BIN_EXE_nnue-eval"))
        .args(args)
        .output()
        .expect("nnue-eval runs")
}

#[test]
fn positions_score_as_the_engines_nnue_eval_scored_them() {
    let (dir, net) = scratch("fens");
    let fens = dir.join("fens.txt");
    let text: String = EXPECTED.iter().map(|(_, fen)| format!("{fen}\n")).collect();
    std::fs::write(&fens, text).unwrap();
    let out = nnue_eval(&[
        "--net",
        net.to_str().unwrap(),
        "--fens",
        fens.to_str().unwrap(),
    ]);
    assert!(
        out.status.success(),
        "{}",
        String::from_utf8_lossy(&out.stderr)
    );
    let want: String = EXPECTED
        .iter()
        .map(|(cp, fen)| format!("{cp} | {fen}\n"))
        .collect();
    assert_eq!(String::from_utf8(out.stdout).unwrap(), want);
    std::fs::remove_dir_all(&dir).ok();
}

/// `--check` against the trainer's numbers: passes when they agree, and fails
/// (exit 1) when one position is off by more than the bars allow.
#[test]
fn the_check_passes_on_agreement_and_fails_on_a_mismatch() {
    let (dir, net) = scratch("check");
    let check = |offset: f64| {
        let entries: Vec<serde_json::Value> = EXPECTED
            .iter()
            .enumerate()
            .map(|(i, (cp, fen))| {
                let off = if i == 3 { offset } else { 0.0 };
                serde_json::json!({"fen": fen, "trainer_cp": *cp as f64 + off})
            })
            .collect();
        let path = dir.join(format!("eval_check-{offset}.json"));
        std::fs::write(&path, serde_json::to_string(&entries).unwrap()).unwrap();
        nnue_eval(&[
            "--net",
            net.to_str().unwrap(),
            "--check",
            path.to_str().unwrap(),
        ])
        .status
        .code()
    };
    assert_eq!(check(0.0), Some(0));
    assert_eq!(check(400.0), Some(1));
    std::fs::remove_dir_all(&dir).ok();
}

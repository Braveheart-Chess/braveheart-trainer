//! One engine for the whole repository: nnue-eval (this workspace's
//! Cargo.lock) and the trainer's tests (trainer/Cargo.lock) are pinned to the
//! same engine commit, so a net is trained, laid out and checked against one
//! engine release.

fn engine_source(lock: &str) -> &str {
    let block = lock
        .split("[[package]]")
        .find(|b| {
            b.lines()
                .any(|l| l.trim() == "name = \"braveheart-search\"")
        })
        .expect("braveheart-search in the lock");
    block
        .lines()
        .find_map(|l| l.strip_prefix("source = "))
        .expect("braveheart-search comes from git")
}

#[test]
fn nnue_eval_and_the_trainer_pin_the_same_engine() {
    let here = engine_source(include_str!("../../../Cargo.lock"));
    let trainer = engine_source(include_str!("../../../trainer/Cargo.lock"));
    assert!(
        here.contains("github.com/Braveheart-Chess/braveheart?tag="),
        "{here}"
    );
    assert_eq!(here, trainer);
}

fn script(name: &str) -> String {
    let out = std::process::Command::new("bash")
        .arg(format!("{}/../../ci/{name}", env!("CARGO_MANIFEST_DIR")))
        .output()
        .unwrap_or_else(|e| panic!("bash runs ci/{name}: {e}"));
    assert!(
        out.status.success(),
        "ci/{name}: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    String::from_utf8(out.stdout).unwrap().trim().to_string()
}

fn locked(field: &str) -> String {
    let lock = include_str!("../../../Cargo.lock");
    let block = lock
        .split("[[package]]")
        .find(|b| {
            b.lines()
                .any(|l| l.trim() == "name = \"braveheart-search\"")
        })
        .expect("braveheart-search in the lock");
    let line = block
        .lines()
        .find(|l| l.starts_with(field))
        .expect("the field");
    line.split('"').nth(1).unwrap().to_string()
}

/// Train records the engine ci/engine-pin.sh names: the lock's.
#[test]
fn the_task_scripts_read_the_lock_s_engine() {
    let commit = locked("source").rsplit_once('#').unwrap().1.to_string();
    assert_eq!(
        script("engine-pin.sh"),
        format!("{} {commit}", locked("version"))
    );
}

/// Train reads the net shapes the engine accepts from this file: the pinned
/// commit's own nnue.rs, which lists them.
#[test]
fn the_engine_source_train_reads_is_the_pinned_commit_s() {
    let path = script("engine-nnue-rs.sh");
    let commit = locked("source").rsplit_once('#').unwrap().1.to_string();
    assert!(
        path.contains(&format!("/{}/", &commit[..7])),
        "{path} is not commit {commit}"
    );
    let source = std::fs::read_to_string(&path).unwrap();
    for name in [
        "pub const WIDTHS",
        "pub const NETS",
        "pub const KING_BUCKET_LAYOUT",
    ] {
        assert!(source.contains(name), "{path} has no `{name}`");
    }
}

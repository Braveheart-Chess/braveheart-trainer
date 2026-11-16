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

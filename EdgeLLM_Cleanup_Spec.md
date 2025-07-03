# EdgeLLM Repository – Cleanup & Release Checklist
*Generated: 2025-07-03*

---

## 🎯 Goal  
Refactor the existing `complete-package` branch so that EdgeLLM can be consumed as a lightweight Swift Package via SPM.  Remove giant artefacts, fix dependency paths, and set up CI.

---

## ❶ Remove build artefacts from Git history
Folders `build_xcframework/`, `dist_complete/`, `build_complete/` add >300 MB.

```bash
git rm -r --cached build_xcframework dist_complete build_complete
echo 'build_xcframework/' >> .gitignore
echo 'dist_complete/'     >> .gitignore
echo 'build_complete/'    >> .gitignore
git commit -m "chore: remove build artefacts"
git push
```

*Done if* fresh clone is <15 MB.

---

## ❷ Fix Package.swift
*Problem*: relative path `package(path:"../ios/MLCSwift")`.

**Fix**

* Copy MLCSwift source into `Sources/MLCSwift/`.
* Add MLCRuntime as a binary target (zip, ≤7 MB).
* EdgeLLM depends on MLCSwift.

---

## ❸ Off‑load full models
Only keep a ≤60 MB demo model in `Resources/bundle/`; download the full model at runtime via `ensureModelIsReady()`.

---

## ❹ Add CI & Release
`.github/workflows/ci.yml`  
* macOS 14 runner, `swift build -c release`.  
* Upload XCFramework + model to release assets when a tag is pushed.

---

## ❺ Unify license
Use Apache‑2.0 for the entire repo; add `LICENSE-THIRD-PARTY.txt` referencing MLC‑LLM.

---

## ✔ Acceptance checklist
* Clone size <15 MB  
* `swift build -c release` passes  
* First run downloads model; second run instant  
* Release v0.1.1 contains XCFramework, model, checksum  
* README shows 1‑line install & 5‑line usage example  
* PR comment **DONE** when finished

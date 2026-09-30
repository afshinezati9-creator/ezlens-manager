# Push to GitHub → Build Android APK

Repo: https://github.com/afshinezati9-creator/ezlens-manager

## Windows CMD (from project folder)

```bat
cd /d "C:\Users\1\Desktop\New folder\ezlens-manager-main"

git init
git branch -M main
git add .
git status

git commit -m "release: manager app phase3 debug + multi-session ready"

git remote remove origin 2>nul
git remote add origin https://github.com/afshinezati9-creator/ezlens-manager.git

git pull origin main --rebase --allow-unrelated-histories
git push -u origin main
```

If pull conflicts: prefer local files, then push.

```bat
git push -u origin main --force
```

Use force only if you intend to replace remote with this folder.

## After push

1. Open: https://github.com/afshinezati9-creator/ezlens-manager/actions
2. Workflow **Build Android APK** runs on `main`
3. Wait until green (about 5–10 min)
4. Artifacts → **ezlens-manager-apk** → download APK

## Manual re-run

Actions → Build Android APK → Run workflow → Branch main

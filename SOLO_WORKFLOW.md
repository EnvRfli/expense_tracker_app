# 🧑‍💻 Solo Developer Git Workflow - Simplified

## 🎯 Simplified Branch Strategy

### **Main Branches:**
- `main` - Production releases (v1.0.0, v1.1.0, etc.)
- `develop` - Your main working branch (daily development)

### **Optional Branches (when needed):**
- `hotfix/critical-bug` - Only for urgent production fixes

## 🔄 Daily Development Workflow

### **Normal Development (90% of time):**
```bash
# Work directly on develop branch
git checkout develop
git pull origin develop

# Make changes...
git add .
git commit -m "fix: resolve budget calculation error"
git push origin develop

# OR for bigger features
git commit -m "feat: add custom category colors"
git push origin develop
```

### **Before Release:**
```bash
# When ready for release (e.g., v1.1.0)
git checkout develop
# Final testing, update version numbers
git add .
git commit -m "chore: prepare for v1.1.0 release"

# Merge to main
git checkout main
git merge develop
git tag v1.1.0
git push origin main --tags

# Build APK and create GitHub Release
```

### **Critical Hotfix (rare):**
```bash
# Only when production has critical bug
git checkout main
git checkout -b hotfix/critical-payment-bug
# Fix critical bug...
git commit -m "hotfix: fix critical payment calculation"
git push origin hotfix/critical-payment-bug

# Merge to main
git checkout main
git merge hotfix/critical-payment-bug
git tag v1.0.1
git push origin main --tags

# Merge back to develop
git checkout develop
git merge main
git push origin develop
```

## 📝 Simplified Commit Messages

### **Keep it simple:**
- `fix: [what you fixed]`
- `feat: [what you added]`
- `update: [what you updated]`
- `refactor: [what you cleaned up]`

### **Examples:**
```bash
git commit -m "fix: budget calculation error"
git commit -m "feat: add dark mode toggle"
git commit -m "update: improve expense list UI"
git commit -m "refactor: clean up unused code"
```

## 🏷️ Version Numbers

### **Simple approach:**
- **Bug fixes**: `1.0.0` → `1.0.1`
- **New features**: `1.0.1` → `1.1.0`
- **Major changes**: `1.1.0` → `2.0.0`

## 🚀 Release Process

1. **Work on develop** for days/weeks
2. **Test everything** works well
3. **Update version** in pubspec.yaml
4. **Merge to main**
5. **Tag release**
6. **Build APK**
7. **Create GitHub Release**
8. **Continue development on develop**

## 💡 Pro Tips for Solo Developer

### **DO:**
- ✅ Commit often with clear messages
- ✅ Use develop for daily work
- ✅ Test before merging to main
- ✅ Keep main stable for releases
- ✅ Use descriptive commit messages

### **DON'T:**
- ❌ Overcomplicate with too many branches
- ❌ Work directly on main
- ❌ Push broken code to develop
- ❌ Skip testing before release

---
**Perfect for solo developers: Simple but organized!**

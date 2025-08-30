# 🌿 Git Workflow Strategy - Expense Tracker App

## 🎯 Branch Strategy

### **Main Branches:**
- `main` - Production-ready code (stable releases)
- `develop` - Integration branch for features

### **Supporting Branches:**
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Critical production fixes
- `release/*` - Release preparation

## 🔄 Development Workflow

### **1. Setup Development Branch**
```bash
git checkout -b develop
git push -u origin develop
```

### **2. Feature Development**
```bash
# Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/expense-categories
# Work on feature...
git add .
git commit -m "feat: add new expense categories"
git push origin feature/expense-categories
# Create PR to develop
```

### **3. Bug Fixes**
```bash
# Create bugfix branch from develop
git checkout develop
git pull origin develop
git checkout -b bugfix/calculation-error
# Fix bug...
git add .
git commit -m "fix: resolve calculation error in budget screen"
git push origin bugfix/calculation-error
# Create PR to develop
```

### **4. Release Process**
```bash
# Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/v1.1.0
# Update version numbers, final testing...
git add .
git commit -m "chore: bump version to 1.1.0"
git push origin release/v1.1.0
# Create PR to main
# After merge, tag release
git checkout main
git pull origin main
git tag v1.1.0
git push origin v1.1.0
```

## 📝 Commit Message Convention

### **Format:**
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### **Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

### **Examples:**
```bash
feat(budget): add recurring budget alerts
fix(calculation): resolve expense total calculation error
docs(readme): update installation instructions
style(ui): improve button spacing
refactor(auth): simplify login flow
test(budget): add unit tests for budget calculations
chore(deps): update Flutter dependencies
```

## 🏷️ Version Numbering

Follow Semantic Versioning (SemVer): `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### **Examples:**
- `1.0.0` → `1.0.1` (bug fix)
- `1.0.1` → `1.1.0` (new feature)
- `1.1.0` → `2.0.0` (breaking change)

## 🚀 Release Process

1. **Feature Complete** in develop
2. **Create release branch** (`release/v1.1.0`)
3. **Final testing & bug fixes**
4. **Update version numbers**
5. **Merge to main**
6. **Create GitHub Release**
7. **Build & distribute APK**
8. **Merge back to develop**

---
**Next Version Planning: v1.1.0**

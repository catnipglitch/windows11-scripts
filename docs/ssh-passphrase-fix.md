# Git push で SSH パスフレーズを毎回聞かれる問題と対策

## 環境

- Windows 11
- VS Code
- Git for Windows
- GitHub（SSH接続）

---

## 問題

`git push` のたびに SSH パスフレーズを **2回** 聞かれる。

```
Enter passphrase for key '/c/Users/<user>/.ssh/id_ed25519':
Enter passphrase for key '/c/Users/<user>/.ssh/id_ed25519':
```

`ssh -T git@github.com` は1回で通るのに、`git push` だと2回聞かれる。

---

## 原因

Git for Windows に同梱された SSH（`/c/Users/...` パス形式）が使われていた。

- Git Bash 付属の SSH は **Windows の `ssh-agent` を参照しない**
- そのため `ssh-agent` にキーを登録済みでも毎回パスフレーズが要求される
- 2回聞かれるのは Git が内部で2本の SSH セッションを張るため

### 診断コマンドと出力例

```powershell
$env:GIT_SSH_COMMAND="ssh -v"; git push
```

Git Bash の SSH が使われている場合、ログの冒頭が以下のようになる：

```
OpenSSH_9.9p1, OpenSSL 3.2.3 3 Sep 2024
debug1: Reading configuration data /c/Users/<user>/.ssh/config
                                    ^^^
                                    /c/ 形式 → Git Bash のSSH
```

Windows 標準の SSH なら `C:\Users\...` 形式になる。

---

## 対策

Git が使う SSH を Windows 標準の OpenSSH に統一する。

### 手順

**1. 不要な環境変数をクリア**

```powershell
Remove-Item Env:GIT_SSH_COMMAND -ErrorAction SilentlyContinue
Remove-Item Env:GIT_SSH -ErrorAction SilentlyContinue
```

**2. Git の SSH コマンドを Windows 標準に固定**

```powershell
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
```

**3. 設定確認**

```powershell
git config --global core.sshCommand
# → C:/Windows/System32/OpenSSH/ssh.exe
```

**4. ssh-agent が起動済みでキーが登録されているか確認**

```powershell
Get-Service ssh-agent       # Running であること
ssh-add -l                  # キーが表示されること
```

ssh-agent が停止している場合：

```powershell
# 管理者 PowerShell で実行
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent
ssh-add ~/.ssh/id_ed25519
```

---

## 確認

```powershell
git push
```

パスフレーズを聞かれずに push できれば解決。

---

## 補足：WSL でも同様の問題が起きる場合

WSL 側も同じ構成の場合、WSL の `~/.gitconfig` に同様の設定が必要になる可能性がある。WSL から Windows の ssh-agent を参照する設定については別途対応が必要。

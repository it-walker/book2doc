-- ログを記録する関数
on writeLog(logMessage)
	try
		set logFile to (POSIX path of (path to desktop folder)) & "book2doc_" & (do shell script "date +%Y%m%d") & ".log"
		do shell script "echo '[" & (do shell script "date +%Y-%m-%d\\ %H:%M:%S") & "] " & logMessage & "' >> " & quoted form of logFile
	on error errMsg
		display dialog "ログの記録に失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end writeLog

-- 新規フォルダを作成する関数
on createFolder(folderPath)
	try
		do shell script "mkdir -p " & quoted form of folderPath
		writeLog("フォルダを作成しました: " & folderPath)
		return true
	on error errMsg
		writeLog("エラー: フォルダの作成に失敗しました: " & errMsg)
		display dialog "フォルダの作成に失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
		return false
	end try
end createFolder

-- スクリーンショットを撮る関数
on takeScreenshot(savePath, captureRect)
	try
		-- captureRect は "x,y,width,height" 形式の文字列
		do shell script "screencapture -R " & captureRect & " " & quoted form of savePath
		writeLog("スクリーンショットを保存しました: " & savePath)
		return true
	on error errMsg
		writeLog("エラー: スクリーンショットの撮影に失敗しました: " & errMsg)
		display dialog "スクリーンショットの撮影に失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
		return false
	end try
end takeScreenshot

-- OCR処理を実行する関数
on performOCR(folderPath)
	try
		-- スクリプトのフルパスを取得
		set scriptPath to POSIX path of (path to me as text)
		-- ディレクトリ部分だけ取り出す（dirnameコマンド使用）
		set appDir to do shell script "dirname " & quoted form of scriptPath
		-- main.pyのパスを構築
		set pythonScriptPath to appDir & "/main.py"
		writeLog("Pythonスクリプトのパス: " & pythonScriptPath)
		
		-- Pythonスクリプトの存在確認
		do shell script "test -f " & quoted form of pythonScriptPath
		writeLog("Pythonスクリプトの存在を確認しました")
		
		-- OCR処理を実行
		writeLog("OCR処理を開始します")
		do shell script "python " & quoted form of pythonScriptPath & " " & quoted form of folderPath
		writeLog("OCR処理が完了しました")
		return true
	on error errMsg
		writeLog("エラー: OCR処理に失敗しました: " & errMsg)
		display dialog "OCR処理に失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
		return false
	end try
end performOCR

-- 画像ファイルを削除する関数
on deleteFiles(filePaths)
	repeat with f in filePaths
		do shell script "rm " & quoted form of f
	end repeat
end deleteFiles

-- メインスクリプト
-- ページめくり方向の定義
set totalPages to 317 -- スクリーンショット数
set keychar to (ASCII character 29) -- ページめくり方向(28=左,29=右)
set currentDate to do shell script "date +%Y%m%d_%H%M%S"
set folderPath to (POSIX path of (path to desktop folder)) & "Kindle_Screenshots_" & currentDate & "/"

-- キャプチャする範囲を指定 (x, y, width, height)
set captureRect to "390,99,754,926"

-- 処理開始の確認
writeLog("スクリプトを開始します")
set startResponse to display dialog "スクリーンショットの取得とOCR処理を開始しますか？" & return & return & "処理内容:" & return & "1. スクリーンショットの取得" & return & "2. OCR処理の実行" & return & "3. Google Driveへのアップロード" buttons {"開始", "キャンセル"} default button "開始"
if button returned of startResponse is "キャンセル" then
	writeLog("ユーザーによって処理がキャンセルされました")
	return
end if
writeLog("処理を開始します")

-- 新規フォルダの作成
if not createFolder(folderPath) then
	return
end if

-- Kindleアプリの前面化
try
	tell application "Amazon Kindle" to activate
	writeLog("Kindleアプリを前面化しました")
on error errMsg
	writeLog("エラー: Kindleアプリの起動に失敗しました: " & errMsg)
	display dialog "Kindleアプリの起動に失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
	return
end try

-- スクリーンショットを取得
set screenshotPaths to {}
repeat with i from 1 to totalPages
	-- 進捗表示
	writeLog("スクリーンショット " & i & "/" & totalPages & " を取得中")
	
	set screenshotPath to folderPath & "screenshot_" & i & ".png"

	-- マウスを画面外に移動（ページ移動ボタンを非表示にするため）
	try
		tell application "System Events"
			set mousePosition to {0, 0}
			set mousePosition to mousePosition
		end tell
		writeLog("マウスを画面外に移動しました")
	on error errMsg
		writeLog("エラー: マウス移動に失敗しました: " & errMsg)
		display dialog "マウス移動に失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
		return
	end try
	
	delay 0.5 -- マウス移動後の待機時間
	
	-- スクリーンショットを撮影
	if not takeScreenshot(screenshotPath, captureRect) then
		return
	end if
	
	-- スクリーンショットのパスをリストに追加
	copy screenshotPath to end of screenshotPaths
	
	delay 0.3 -- スクリーンショット保存時間
	
	-- ページめくり
	try
		tell application "System Events"
			keystroke keychar
			delay 0.2 -- ページめくり後の安定時間
		end tell
		writeLog("ページをめくりました")
	on error errMsg
		writeLog("エラー: ページめくりに失敗しました: " & errMsg)
		display dialog "ページめくりに失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
		return
	end try
end repeat

-- スクリーンショット取得完了の通知
writeLog("スクリーンショットの取得が完了しました")

-- OCR処理を実行
if not performOCR(folderPath) then
	return
end if

-- 処理完了の通知
writeLog("すべての処理が完了しました")
display dialog "処理が完了しました。" & return & return & "出力フォルダ: " & folderPath & return & "ログファイル: " & (POSIX path of (path to desktop folder)) & "book2doc_" & (do shell script "date +%Y%m%d") & ".log" buttons {"OK"} default button "OK"

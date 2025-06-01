-- グローバル変数の宣言
global pageTurnDirection

-- ログを記録する関数
on writeLog(logMessage)
	try
		set logFile to (POSIX path of (path to desktop folder)) & "book2doc_" & (do shell script "date +%Y%m%d") & ".log"
		set logEntry to "[" & (do shell script "date '+%Y-%m-%d %H:%M:%S'") & "] " & logMessage
		do shell script "echo " & quoted form of logEntry & " >> " & quoted form of logFile
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
on takeScreenshot(folderPath, pageNumber)
	try
		-- スクリーンショット前の待機
		delay 0.3
		
		-- スクリーンショットの取得
		set screenshotPath to folderPath & "screenshot_" & pageNumber & ".png"
		do shell script "screencapture -x -R 390,99,754,926 " & quoted form of screenshotPath
		
		-- スクリーンショット後の待機
		delay 0.3
		
		writeLog("スクリーンショットを保存しました: " & screenshotPath)
		return true
	on error errMsg
		writeLog("スクリーンショットの取得に失敗しました: " & errMsg)
		display dialog "スクリーンショットの取得に失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
		return false
	end try
end takeScreenshot

-- ページをめくる関数
on turnPage()
	try
		-- ページめくり前の待機
		delay 0.3
		
		-- ページめくり
		tell application "System Events"
			keystroke (ASCII character pageTurnDirection)
			delay 0.2 -- ページめくり後の安定時間
		end tell
		
		writeLog("ページをめくりました")
		return true
	on error errMsg
		writeLog("エラー: ページめくりに失敗しました: " & errMsg)
		display dialog "ページめくりに失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
		return false
	end try
end turnPage

-- メインスクリプト
-- ページめくり方向の定義
-- set totalPages to 5 -- テスト用に5ページに変更
set totalPages to 350 -- スクリーンショット数
set pageTurnDirection to 28 -- ページめくり方向(28=左,29=右)
set directionText to "右"
if pageTurnDirection is 28 then
	set directionText to "左"
end if

-- 処理開始の確認
writeLog("スクリプトを開始します")
set startResponse to display dialog "スクリーンショットの取得を開始しますか？" & return & return & "処理内容:" & return & "1. スクリーンショットの取得（" & totalPages & "ページ）" & return & "2. ページめくり方向: " & directionText buttons {"開始", "キャンセル"} default button "開始"
if button returned of startResponse is "キャンセル" then
	writeLog("ユーザーによって処理がキャンセルされました")
	return
end if
writeLog("処理を開始します")

-- 新規フォルダの作成
set currentDate to do shell script "date +%Y%m%d_%H%M%S"
set folderPath to (POSIX path of (path to desktop folder)) & "Kindle_Screenshots_" & currentDate & "/"
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
	
	-- スクリーンショットを撮影
	if not takeScreenshot(folderPath, i) then
		return
	end if
	
	-- スクリーンショットのパスをリストに追加
	copy folderPath & "screenshot_" & i & ".png" to end of screenshotPaths
	
	-- ページめくり
	if not turnPage() then
		return
	end if
end repeat

-- スクリーンショット取得完了の通知
writeLog("スクリーンショットの取得が完了しました")
display dialog "スクリーンショットの取得が完了しました。" & return & return & "出力フォルダ: " & folderPath & return & "ログファイル: " & (POSIX path of (path to desktop folder)) & "book2doc_" & (do shell script "date +%Y%m%d") & ".log" buttons {"OK"} default button "OK" 

-- 新規フォルダを作成する関数
on createFolder(folderPath)
	do shell script "mkdir -p " & quoted form of folderPath
end createFolder

-- スクリーンショットを撮る関数
on takeScreenshot(savePath, captureRect)
	-- captureRect は "x,y,width,height" 形式の文字列
	do shell script "screencapture -R " & captureRect & " " & quoted form of savePath
end takeScreenshot

-- 画像ファイルを削除する関数
on deleteFiles(filePaths)
	repeat with f in filePaths
		do shell script "rm " & quoted form of f
	end repeat
end deleteFiles

-- メインスクリプト
-- ページめくり方向の定義
-- set totalPages to 10 -- スクリーンショット数
set totalPages to 1 -- スクリーンショット数
set keychar to (ASCII character 29) -- ページめくり方向(28=左,29=右)
set currentDate to do shell script "date +%Y%m%d_%H%M%S"
set folderPath to (POSIX path of (path to desktop folder)) & "Kindle_Screenshots_" & currentDate & "/"

-- キャプチャする範囲を指定 (x, y, width, height)
set captureRect to "390,99,754,926"
-- set captureRect to "390,71,754,954"
-- set captureRect to "50,100,1500,850"

-- 新規フォルダの作成
createFolder(folderPath)

-- Kindleアプリの前面化
tell application "Amazon Kindle" to activate

-- スクリーンショットを取得
set screenshotPaths to {}
repeat with i from 1 to totalPages
	set screenshotPath to folderPath & "screenshot_" & i & ".png"

	-- マウスを画面外に移動（ページ移動ボタンを非表示にするため）
	tell application "System Events"
		set mousePosition to {0, 0}
		set mousePosition to mousePosition
	end tell
	
	delay 0.5 -- マウス移動後の待機時間
	
	-- スクリーンショットを撮影
	takeScreenshot(screenshotPath, captureRect)
	
	-- スクリーンショットのパスをリストに追加
	copy screenshotPath to end of screenshotPaths
	
	delay 0.3 -- スクリーンショット保存時間
	
	-- ページめくり
	tell application "System Events"
		keystroke keychar
		delay 0.2 -- ページめくり後の安定時間
	end tell
end repeat

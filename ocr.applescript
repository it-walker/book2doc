-- ログを記録する関数
on writeLog(logMessage)
	try
		set logFile to (POSIX path of (path to desktop folder)) & "book2doc_" & (do shell script "date +%Y%m%d") & ".log"
		set escapedMessage to do shell script "echo " & quoted form of logMessage & " | iconv -f UTF-8 -t UTF-8"
		do shell script "echo '[" & (do shell script "date +%Y-%m-%d\\ %H:%M:%S") & "] " & escapedMessage & "' >> " & quoted form of logFile
	on error errMsg
		display dialog "ログの記録に失敗しました: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
end writeLog

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

-- メインスクリプト
-- 処理開始の確認
writeLog("OCRスクリプトを開始します")
set startResponse to display dialog "OCR処理を開始しますか？" & return & return & "処理内容:" & return & "1. OCR処理の実行" & return & "2. Google Driveへのアップロード" buttons {"開始", "キャンセル"} default button "開始"
if button returned of startResponse is "キャンセル" then
	writeLog("ユーザーによって処理がキャンセルされました")
	return
end if

-- フォルダパスの入力
set folderResponse to display dialog "スクリーンショットが保存されているフォルダのパスを入力してください:" default answer "" buttons {"OK", "キャンセル"} default button "OK"
if button returned of folderResponse is "キャンセル" then
	writeLog("ユーザーによって処理がキャンセルされました")
	return
end if
set folderPath to text returned of folderResponse

-- フォルダの存在確認
try
	do shell script "test -d " & quoted form of folderPath
	writeLog("フォルダの存在を確認しました: " & folderPath)
on error errMsg
	writeLog("エラー: 指定されたフォルダが存在しません: " & errMsg)
	display dialog "指定されたフォルダが存在しません: " & errMsg buttons {"OK"} default button "OK" with icon stop
	return
end try

-- OCR処理を実行
if not performOCR(folderPath) then
	return
end if

-- 処理完了の通知
writeLog("すべての処理が完了しました")
display dialog "処理が完了しました。" & return & return & "出力フォルダ: " & folderPath & return & "ログファイル: " & (POSIX path of (path to desktop folder)) & "book2doc_" & (do shell script "date +%Y%m%d") & ".log" buttons {"OK"} default button "OK" 
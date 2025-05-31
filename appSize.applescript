
set titleBarHeight to 28


-- Kindleアプリの前面化
tell application "Amazon Kindle"
	activate
	delay 1
end tell

-- ウィンドウの位置とサイズを取得
tell application "System Events"
	tell process "Amazon Kindle"
		set windowPosition to position of window 1
		set windowSize to size of window 1
        -- スクリーンショット用の座標形式に変換
        set x to item 1 of windowPosition
        set y to (item 2 of windowPosition) + titleBarHeight
        set width to item 1 of windowSize
        set height to (item 2 of windowSize) - titleBarHeight		
		-- キャプチャ用の座標文字列を作成
		set captureRect to x & "," & y & "," & width & "," & height
		
		-- 座標文字列を表示
		-- display dialog "キャプチャ用の座標: " & captureRect buttons {"OK"} default button "OK"

        -- 結果を表示（コピーボタンを追加）
        set buttonPressed to button returned of (display dialog "ウィンドウの位置: " & windowPosition & return & "ウィンドウのサイズ: " & windowSize & return & return & "キャプチャ用の座標: " & captureRect buttons {"コピー", "キャンセル"} default button "コピー")
        
        -- コピーボタンが押された場合
        if buttonPressed is "コピー" then
			set the clipboard to captureRect as string
            display dialog "コピーしました" buttons {"OK"} default button "OK"
        end if
	end tell
end tell
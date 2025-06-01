# -*- coding: utf-8 -*-
import os
import subprocess
import argparse
from markdown_it import MarkdownIt
from google.cloud import vision_v1
from google.oauth2 import service_account
from googleapiclient.discovery import build
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from PyPDF2 import PdfReader, PdfWriter
import io

# コマンドライン引数の設定
parser = argparse.ArgumentParser(description='KindleスクリーンショットのOCR処理')
parser.add_argument('folder_path', help='スクリーンショットが保存されているフォルダのパス')
args = parser.parse_args()

# パスの設定
folder_path = args.folder_path
if not folder_path.endswith('/'):
    folder_path += '/'
ocr_output_file = folder_path + 'ocr_output.txt'

# 環境変数を設定（サービスアカウントキーのパスを指定）
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'service-account.json'  # 実際のパスに変更

# Google Cloud Vision APIのクライアントを設定
vision_client = vision_v1.ImageAnnotatorClient()

# OCRの実行
def perform_ocr(image_path):
    with open(image_path, 'rb') as image_file:
        content = image_file.read()
    image = vision_v1.Image(content=content)
    response = vision_client.text_detection(image=image)
    texts = response.text_annotations
    if len(texts) > 0:
        return texts[0].description
    else:
        return ''

# 画像ファイルのリスト取得
image_files = [f for f in os.listdir(folder_path) if f.startswith('screenshot_') and f.endswith('.png')]
# 自然な順序でソート（1, 2, 3, ... 10, 11, ...）
image_files.sort(key=lambda x: int(x.split('_')[1].split('.')[0]))

# OCRの実行
ocr_text = ''
total_images = len(image_files)
try:
    with open(ocr_output_file, 'w', encoding='utf-8') as output:
        for i, image in enumerate(image_files, 1):
            image_path = os.path.join(folder_path, image)
            print(f'Processing image {i}/{total_images}: {image_path}')
            text = perform_ocr(image_path)
            ocr_text += text
            output.write(text)
except Exception as e:
    print(f'Error in OCR process: {e}')
    exit(1)

# 最初の10文字を取得してファイル名に使用
try:
    file_name_prefix = ocr_text[:10].strip().replace(' ', '_').replace('/', '_')
    if not file_name_prefix:
        file_name_prefix = 'OCR_Output'
    md_output_file = folder_path + file_name_prefix + '.md'
    ocr_output_file = folder_path + file_name_prefix + '.txt'
    pdf_output_file = folder_path + file_name_prefix + '.pdf'
except Exception as e:
    print(f'Error in generating file names: {e}')
    exit(1)

# Markdown変換
try:
    md = MarkdownIt()
    md_text = md.render(ocr_text)
    with open(md_output_file, 'w', encoding='utf-8') as output:
        output.write(md_text)
except Exception as e:
    print(f'Error in Markdown conversion: {e}')
    exit(1)

# Google Drive にアップロード
try:
    SCOPES = ['https://www.googleapis.com/auth/drive.file']
    SERVICE_ACCOUNT_FILE = 'service-account.json'  # 実際のパスに変更

    credentials = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    drive_service = build('drive', 'v3', credentials=credentials)

    # Google Drive フォルダID
    folder_id = '1Rd4a8Meg9HV3o2t0pMXZ4VPFfz7OXm2N'  # 実際のフォルダIDに変更

    file_metadata = {
        'name': file_name_prefix,
        'parents': [folder_id],
        'mimeType': 'application/vnd.google-apps.document'
    }
    document = drive_service.files().create(body=file_metadata, fields='id').execute()
    doc_id = document['id']

    with open(md_output_file, 'r', encoding='utf-8') as md_file:
        md_content = md_file.read()

    docs_service = build('docs', 'v1', credentials=credentials)
    requests = [{'insertText': {'location': {'index': 1}, 'text': md_content}}]
    docs_service.documents().batchUpdate(documentId=doc_id, body={'requests': requests}).execute()
    print(f'Document created: {doc_id}')
except Exception as e:
    print(f'Error in uploading to Google Docs: {e}')
    exit(1)

# PDFを作成
try:
    # まず画像からPDFを作成
    img_files = [os.path.join(folder_path, f) for f in image_files]
    temp_pdf = folder_path + 'temp.pdf'
    subprocess.run(['/usr/local/bin/img2pdf'] + img_files + ['-o', temp_pdf], check=True)

    # OCRテキストを埋め込んだPDFを作成
    output_pdf = PdfWriter()
    reader = PdfReader(temp_pdf)
    
    for i, (page, image_file) in enumerate(zip(reader.pages, image_files)):
        # 各ページのOCRテキストを取得
        image_path = os.path.join(folder_path, image_file)
        ocr_text = perform_ocr(image_path)
        
        # 新しいPDFページを作成
        packet = io.BytesIO()
        c = canvas.Canvas(packet, pagesize=A4)
        c.setFont("Helvetica", 1)  # 最小のフォントサイズ
        c.setFillColorRGB(1, 1, 1)  # 白色（不可視）
        c.drawString(0, 0, ocr_text)  # テキストを配置
        c.save()
        
        # テキストレイヤーを追加
        packet.seek(0)
        text_pdf = PdfReader(packet)
        page.merge_page(text_pdf.pages[0])
        output_pdf.add_page(page)

    # 最終的なPDFを保存
    with open(pdf_output_file, 'wb') as output_file:
        output_pdf.write(output_file)

    # 一時ファイルを削除
    os.remove(temp_pdf)
    
except Exception as e:
    print(f'Error in PDF creation: {e}')
    exit(1)


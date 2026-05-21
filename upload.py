#!/usr/bin/env python3
"""
LKS Cloud Computing 2026 - Private-Only Upload to S3
Dijalankan dari EC2 di Private Subnet, lewat S3 Gateway Endpoint.
"""

import os
import sys
import boto3
import botocore.exceptions

# ====================================================================
# WAJIB: Sesuikan dengan detail akun AWS / S3 Bucket Lo saat ini!
# ====================================================================
BUCKET_NAME = 'p01-lks-cc-2026-alka'     # Ganti bebas/unik jika belum punya bucket S3
REGION      = 'us-east-1'                # Ubah ke region lo (us-east-1 sesuai lab lo)
LOCAL_FILE  = '/home/ec2-user/index.html'
OBJECT_KEY  = 'index.html'
# ====================================================================

def ensure_index_html(path: str) -> None:
    """Buat index.html lokal kalau belum ada."""
    if not os.path.exists(path):
        # Pastikan direktori tujuan ada (jika di-test di lokal)
        os.makedirs(os.path.dirname(path), exist_ok=True) if os.path.dirname(path) else None
        with open(path, 'w', encoding='utf-8') as f:
            f.write('<!doctype html>\n<html>\n<body>\n'
                    '<h1>LKS Cloud Computing 2026</h1>\n'
                    '</body>\n</html>\n')
        print(f'[+] Created local file: {path}')
    else:
        print(f'[=] Local file already exists: {path}')

def upload(bucket: str, key: str, path: str) -> None:
    s3 = boto3.client('s3', region_name=REGION)
    try:
        s3.put_object(
            Bucket=bucket,
            Key=key,
            Body=open(path, 'rb'),
            ContentType='text/html',
        )
        print(f'[OK] put_object sukses: s3://{bucket}/{key}')
    except botocore.exceptions.ClientError as e:
        print(f'[ERR] ClientError: {e.response["Error"]["Message"]}')
        sys.exit(1)
    except Exception as e:
        print(f'[ERR] Unhandled: {e}')
        sys.exit(1)

def verify(bucket: str, key: str) -> None:
    s3 = boto3.client('s3', region_name=REGION)
    head = s3.head_object(Bucket=bucket, Key=key)
    print(f'[OK] head_object: size={head["ContentLength"]} bytes, fetag={head["ETag"]}')

if __name__ == '__main__':
    # Jika ditest di lokal Windows, sesuaikan sementara LOCAL_FILE ke 'index.html'
    if os.name == 'nt':
        LOCAL_FILE = 'index.html'
        
    ensure_index_html(LOCAL_FILE)
    upload(BUCKET_NAME, OBJECT_KEY, LOCAL_FILE)
    verify(BUCKET_NAME, OBJECT_KEY) 
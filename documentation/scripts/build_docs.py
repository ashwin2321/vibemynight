import os
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

OUT_DIR = r'C:\Users\ADMIN\Downloads\vibemynight-phase1-10\documentation'
os.makedirs(OUT_DIR, exist_ok=True)
print('Directory verified:', OUT_DIR)

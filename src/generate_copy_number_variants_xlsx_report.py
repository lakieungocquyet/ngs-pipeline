import argparse
import pandas as pd
import logging
import time
import xlsxwriter
import pathlib
import sys
import os

def setup_logging(
    logger_name: str,
    log_file_path: str = None
    ):
    logger = logging.getLogger(f"{logger_name}")
    logger.setLevel(logging.INFO)
    
    if logger.hasHandlers():
        logger.handlers.clear()


    COLORS = {
        "DEBUG": "\033[36m",
        "INFO": "\033[32m",
        "WARNING": "\033[33m",
        "ERROR": "\033[31m",
    }
    RESET = "\033[0m"

    def format_log(record, use_color=True):
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(record.created))  # UTC
        level = record.levelname
        message = record.getMessage()

        LEVEL_WIDTH = 9

        raw_block = f"[{level}]"
        level_block = raw_block.ljust(LEVEL_WIDTH)

        if use_color:
            color = COLORS.get(level, "")
            level_colored = f"{color}{level}{RESET}"

            level_block = level_block.replace(level, level_colored)
            timestamp = f"\033[33m{timestamp}\033[0m"

        return f"[{timestamp}] {level_block} {message}"
        

    class SimpleFormatter(logging.Formatter):
        def __init__(self, use_color):
            super().__init__()
            self.use_color = use_color

        def format(self, record):
            return format_log(record, self.use_color)    
        

    # STREAM
    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(SimpleFormatter(use_color=True))
    logger.addHandler(stream_handler)


    # FILE 
    if log_file_path:
        os.makedirs(os.path.dirname(log_file_path), exist_ok=True)
        file_handler = logging.FileHandler(f"{log_file_path}", mode="a", encoding="utf-8")
        file_handler.setFormatter(SimpleFormatter(use_color=False))
        logger.addHandler(file_handler)
    
    return logger

setup_logging(
        logger_name = "logger",
    )
logger = logging.getLogger("logger")

parser = argparse.ArgumentParser(
        description = "None"
    )
parser.add_argument(
        "-I", "--input",
        required = True, 
        type = str, 
        help = "None"
    )

parser.add_argument(
        "-O", "--output",
        required = True, 
        type = str, 
        help = "None"
    )
arguments = parser.parse_args()

input_file_path = arguments.input
output_file_path = arguments.output

HEADER = [
    "CHROM", "START", "END", "GENE", "Log2", "COPY NUMBER", "DEPTH", "P_TTEST", "PROBES", "WEIGHT"
]

NEW_HEADER = [
    "CHROM", "START", "END", "Log2", "COPY NUMBER", "DEPTH", "P_TTEST", "PROBES", "WEIGHT", "GENE"
]

data_frame = pd.read_csv(
    input_file_path,
    sep="\t",
    skiprows=1,
    header=None,
    names=HEADER
)
data_frame = data_frame[NEW_HEADER]

with pd.ExcelWriter(f"{output_file_path}", engine="xlsxwriter") as writer:
    data_frame_filled = data_frame.fillna(".")
    data_frame_filled.to_excel(writer, index=False, sheet_name="Sheet 1")
    workbook = writer.book
    worksheet = writer.sheets["Sheet 1"]

    header_format = workbook.add_format({
        'bold': True,
        'font_color': 'black',
        'font_size': 9,  
        'bg_color': "#ADCAE6",
        'border': 1,
        'font_name': 'Arial',
        'align': 'center',
        'valign': 'vcenter',
        'text_wrap': True,
    })
    data_format = workbook.add_format({
        'font_name': 'Arial',
        'font_color': 'black',
        'font_size': 9,  
        'bold': False,
        'text_wrap': False, 
        'align': 'general' 
    })
    # Add header format
    for col_num, value in enumerate(data_frame.columns.values):
        worksheet.write(0, col_num, value, header_format)

    wrap_format = workbook.add_format({
        'text_wrap': True,
    })

    for i, col in enumerate(data_frame.columns):
        if col == "COPY NUMBER":
            worksheet.set_column(i, i, 20, wrap_format)
        else:
            worksheet.set_column(i, i, 15, wrap_format)
    # Set filter for the header row
    worksheet.autofilter(0, 0, 0, len(data_frame.columns)-1)

    row_height = 1 * 20
    worksheet.set_row(0, row_height)

    for row_num in range(1, len(data_frame_filled) + 1):
        worksheet.set_row(row_num, 15.5, data_format)

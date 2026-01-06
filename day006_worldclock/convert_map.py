import fitz  # PyMuPDF
from PIL import Image
import os

def convert_svg_to_bmp(svg_path, bmp_path):
    print(f"Converting {svg_path} to {bmp_path} using PyMuPDF...")
    
    try:
        doc = fitz.open(svg_path)
        page = doc.load_page(0)
        pix = page.get_pixmap()
        
        # Save directly to BMP if supported, or PNG then convert
        # pymupdf pixmap save supports png, ppm, pam, jpg... not explicitly bmp in all versions
        # Safer to save as PNG then use Pillow
        
        png_path = "temp_map.png"
        pix.save(png_path)
        
        # Convert to BMP using Pillow
        with Image.open(png_path) as img:
            rgb_img = img.convert("RGB")
            rgb_img.save(bmp_path)
            
        print("Conversion successful.")
        
        # Cleanup
        if os.path.exists(png_path):
            os.remove(png_path)
            
    except Exception as e:
        print(f"Error during conversion: {e}")

if __name__ == "__main__":
    convert_svg_to_bmp("world_map.svg", "world_map.bmp")

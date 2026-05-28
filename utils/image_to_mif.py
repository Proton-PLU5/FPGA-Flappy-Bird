import os
from PIL import Image

# Configuration
INPUT_FOLDER = "utils/backgrounds"  # Folder containing input images
OUTPUT_FILE = "utils/outputs/backgrounds.mif"
TARGET_WIDTH = 320
TARGET_HEIGHT = 240

def generate_mif():
    if not os.path.exists(INPUT_FOLDER):
        print(f"Error: Folder '{INPUT_FOLDER}' not found.")
        return

    image_files = [f for f in os.listdir(INPUT_FOLDER) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    image_files.sort() # Ensure consistent ordering
    
    if not image_files:
        print("No images found in the input folder.")
        return

    num_images = len(image_files)
    pixels_per_image = TARGET_WIDTH * TARGET_HEIGHT
    total_depth = num_images * pixels_per_image

    print(f"Found {num_images} images. Total depth: {total_depth} words.")

    with open(OUTPUT_FILE, 'w') as f:
        # MIF Header
        f.write(f"DEPTH = {total_depth};\n")
        f.write("WIDTH = 12;\n")
        f.write("ADDRESS_RADIX = DEC;\n")
        f.write("DATA_RADIX = HEX;\n\n")
        f.write("CONTENT BEGIN\n")

        address = 0
        
        for img_idx, filename in enumerate(image_files):
            print(f"Processing {filename} (ID: {img_idx})...")
            filepath = os.path.join(INPUT_FOLDER, filename)
            
            # Open, resize, and convert to RGB
            img = Image.open(filepath).convert('RGB')
            img = img.resize((TARGET_WIDTH, TARGET_HEIGHT), Image.Resampling.BILINEAR)
            
            for y in range(TARGET_HEIGHT):
                for x in range(TARGET_WIDTH):
                    r, g, b = img.getpixel((x, y))
                    
                    # Quantize 8-bit color down to 4-bit color (DE0-CV VGA uses 4 bits per channel)
                    r_4bit = r >> 4
                    g_4bit = g >> 4
                    b_4bit = b >> 4
                    
                    # Pack into a 12-bit hex value
                    color_hex = f"{r_4bit:1X}{g_4bit:1X}{b_4bit:1X}"
                    
                    f.write(f"\t{address} : {color_hex};\n")
                    address += 1

        f.write("END;\n")
    print(f"Successfully generated {OUTPUT_FILE}")

if __name__ == "__main__":
    generate_mif()
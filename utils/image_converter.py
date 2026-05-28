from PIL import Image
import os

def convert_images_to_vhdl_package(input_dir, output_path):
    """
    Convert PNG images to a VHDL package. 
    Uses Quantization to ensure a 16-color limit (15 colors + 1 transparent).
    """

    try:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
    except Exception as e:
        print(f"Error creating output directory: {e}")

    sprites = []

    # Process all PNG files
    for filename in os.listdir(input_dir):
        if not filename.lower().endswith('.png'):
            continue

        image_path = os.path.join(input_dir, filename)
        sprite_name = filename.replace('.png', '').replace(' ', '_').upper()

        # 1. Open image and ensure RGBA
        img = Image.open(image_path).convert('RGBA')
        width, height = img.size

        # 2. Extract Alpha Mask
        # We use this to force Index 0 regardless of what the quantizer thinks
        alpha = img.getchannel('A')
        mask = list(alpha.getdata())

        # 3. Quantize the RGB portion to 15 colors
        # We use 15 because Index 0 is reserved for transparency
        rgb_img = img.convert('RGB')
        quantized = rgb_img.quantize(colors=15, method=Image.Quantize.MAXCOVERAGE)
        
        # 4. Build the 12-bit VHDL Palette
        # Get the palette (comes as a flat list [r,g,b, r,g,b...])
        raw_palette = quantized.getpalette()[:45] # 15 colors * 3 components
        
        palette_12bit = ['x"000"'] # Index 0: Transparent (represented as black)
        
        for i in range(0, len(raw_palette), 3):
            r, g, b = raw_palette[i], raw_palette[i+1], raw_palette[i+2]
            # Convert 8-bit to 4-bit (12-bit total)
            r_4 = (r >> 4) & 0xF
            g_4 = (g >> 4) & 0xF
            b_4 = (b >> 4) & 0xF
            palette_12bit.append(f'x"{r_4:X}{g_4:X}{b_4:X}"')

        # 5. Map Pixels to Indices
        # We shift all quantized indices up by 1 to make room for transparency at 0
        pixel_indices = list(quantized.getdata())
        final_pixel_data = []

        for i, val in enumerate(pixel_indices):
            if mask[i] < 128: # If pixel is more than 50% transparent
                final_pixel_data.append('0')
            else:
                # Map quantized index (0-14) to palette index (1-15)
                final_pixel_data.append(str(val + 1))

        sprites.append({
            'name': sprite_name,
            'width': width,
            'height': height,
            'palette': palette_12bit,
            'pixel_data': final_pixel_data
        })

    # -------------------------------------------------
    # Write VHDL package
    # -------------------------------------------------

    with open(output_path, 'w') as f:
        f.write("library IEEE;\n")
        f.write("use IEEE.std_logic_1164.all;\n\n")
        f.write("package sprite_data_pkg is\n\n")

        # Constants for sizes
        for sprite in sprites:
            f.write(f"    constant {sprite['name']}_WIDTH  : integer := {sprite['width']};\n")
            f.write(f"    constant {sprite['name']}_HEIGHT : integer := {sprite['height']};\n")
        f.write("\n")

        # Palette and Data arrays
        for sprite in sprites:
            f.write(f"    -- {sprite['name']} Resources\n")
            
            # Palette
            pal_len = len(sprite['palette'])
            f.write(f"    type {sprite['name']}_palette_t is array(0 to {pal_len - 1}) of std_logic_vector(11 downto 0);\n")
            f.write(f"    constant {sprite['name']}_PALETTE : {sprite['name']}_palette_t := (\n")
            for i, color in enumerate(sprite['palette']):
                comma = "," if i < pal_len - 1 else ""
                f.write(f"        {color}{comma}\n")
            f.write("    );\n\n")

            # Pixel Data
            pix_len = len(sprite['pixel_data'])
            f.write(f"    type {sprite['name']}_data_t is array(0 to {pix_len - 1}) of integer range 0 to 15;\n")
            f.write(f"    constant {sprite['name']}_DATA : {sprite['name']}_data_t := (\n")

            for i, pixel in enumerate(sprite['pixel_data']):
                comma = "," if i < pix_len - 1 else ""
                f.write(f"{pixel}{comma}")
                
                # Formatting: Add a newline and comment at the end of every row
                if (i + 1) % sprite['width'] == 0:
                    f.write(f" -- row {(i + 1) // sprite['width'] - 1}\n        ")
                else:
                    f.write(" ")

            f.write("\n    );\n\n")

        f.write("end package;\n")

    print(f"Successfully generated: {output_path}")

if __name__ == "__main__":
    # Update these paths as needed
    current_dir = os.getcwd()
    in_dir = os.path.join(current_dir, 'utils/inputs')
    out_file = os.path.join(current_dir, 'utils/outputs', 'sprite_data_pkg.vhd')

    convert_images_to_vhdl_package(in_dir, out_file)
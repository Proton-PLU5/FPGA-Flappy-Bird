from PIL import Image
import os

def convert_images_to_vhdl_package(input_dir, output_path):
    """Convert all PNG images to a single VHDL package with transparency support."""

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
        sprite_name = filename.replace('.png', '').upper()

        # Open image
        image = Image.open(image_path).convert('RGBA')
        width, height = image.size

        # -----------------------------------------
        # Build palette
        # Palette index 0 is ALWAYS transparent
        # -----------------------------------------

        unique_colors = list(set(image.getdata()))

        transparent_colors = []
        visible_colors = []

        for color in unique_colors:
            r, g, b, a = color

            if a == 0:
                transparent_colors.append(color)
            else:
                visible_colors.append(color)

        palette = []

        # Force transparent color into palette slot 0
        if transparent_colors:
            palette.append(transparent_colors[0])
        else:
            # fallback transparent entry
            palette.append((0, 0, 0, 0))

        # Add visible colors after transparency
        palette.extend(visible_colors)

        # Limit palette to 16 colors total
        palette = palette[:16]

        # Create color lookup
        color_to_index = {
            color: index for index, color in enumerate(palette)
        }

        # -----------------------------------------
        # Convert palette to 12-bit RGB
        # -----------------------------------------

        palette_12bit = []

        for r, g, b, a in palette:

            # Transparent color stored as black
            if a == 0:
                palette_12bit.append('x"000"')
            else:
                r_12 = (r >> 4) & 0xF
                g_12 = (g >> 4) & 0xF
                b_12 = (b >> 4) & 0xF

                palette_12bit.append(
                    f'x"{r_12:X}{g_12:X}{b_12:X}"'
                )

        # -----------------------------------------
        # Generate sprite pixel indices
        # -----------------------------------------

        pixel_data = []

        for y in range(height):
            for x in range(width):

                pixel = image.getpixel((x, y))

                # Any transparent pixel -> palette 0
                if pixel[3] == 0:
                    pixel_data.append('0')

                elif pixel in color_to_index:
                    pixel_data.append(
                        str(color_to_index[pixel])
                    )

                else:
                    # fallback
                    pixel_data.append('0')

        sprites.append({
            'name': sprite_name,
            'width': width,
            'height': height,
            'palette': palette_12bit,
            'pixel_data': pixel_data
        })

    # -------------------------------------------------
    # Write VHDL package
    # -------------------------------------------------

    with open(output_path, 'w') as f:

        f.write("library IEEE;\n")
        f.write("use IEEE.std_logic_1164.all;\n\n")

        f.write("package sprite_data_pkg is\n\n")

        # Sprite metadata
        for sprite in sprites:

            f.write(
                f"    constant {sprite['name']}_WIDTH  : integer := {sprite['width']};\n"
            )

            f.write(
                f"    constant {sprite['name']}_HEIGHT : integer := {sprite['height']};\n"
            )

        f.write("\n")

        # Palette + pixel data
        for sprite in sprites:

            f.write(f"    -- {sprite['name']}\n")

            # Palette type
            f.write(
                f"    type {sprite['name']}_palette_t is array(0 to {len(sprite['palette']) - 1}) of std_logic_vector(11 downto 0);\n"
            )

            # Palette data
            f.write(
                f"    constant {sprite['name']}_PALETTE : {sprite['name']}_palette_t := (\n"
            )

            for i, color in enumerate(sprite['palette']):

                comma = "," if i < len(sprite['palette']) - 1 else ""

                f.write(f"        {color}{comma}\n")

            f.write("    );\n\n")

            # Sprite pixel data type
            f.write(
                f"    type {sprite['name']}_sprite_t is array(0 to {len(sprite['pixel_data']) - 1}) of integer range 0 to {len(sprite['palette']) - 1};\n"
            )

            # Pixel data
            f.write(
                f"    constant {sprite['name']}_DATA : {sprite['name']}_sprite_t := (\n"
            )

            for i, pixel in enumerate(sprite['pixel_data']):

                comma = "," if i < len(sprite['pixel_data']) - 1 else ""

                f.write(f"        {pixel}{comma}")

                if (i + 1) % sprite['width'] == 0:
                    f.write("  -- row\n")
                else:
                    f.write(" ")

            f.write("    );\n\n")

        f.write("end package;\n")

    print(f"Generated {output_path} with {len(sprites)} sprites")


if __name__ == "__main__":

    current_directory = os.getcwd()

    input_dir = os.path.join(
        current_directory,
        'utils/inputs'
    )

    output_path = os.path.join(
        current_directory,
        'utils/outputs',
        'sprite_data_pkg.vhd'
    )

    convert_images_to_vhdl_package(
        input_dir,
        output_path
    )
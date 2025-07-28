import os
from imageio.v2 import imread, imwrite

# Imagen de origen
image = imread(r'C:\Users\cruza\Downloads\image.png')

# Rutas de salida en la carpeta del script
base_path = os.path.dirname(__file__)
mi_path = os.path.join(base_path, "init.mi")
output_path = os.path.join(base_path, "image2.png")

red = image[:, :, 0]
green = image[:, :, 1]
blue = image[:, :, 2]

# Crear archivo init.mi
with open(mi_path, "w") as f:
    f.write("#File_format=Bin\n")
    f.write(f"#Address_depth={blue.shape[0] * blue.shape[1]}\n")
    f.write("#Data_width=16\n")
    for row in range(blue.shape[0]):
        for col in range(blue.shape[1]):
            r_val = bin(red[row][col])[2:].zfill(8)[:5]
            g_val = bin(green[row][col])[2:].zfill(8)[:6]
            b_val = bin(blue[row][col])[2:].zfill(8)[:5]
            f.write(f"{r_val}{g_val}{b_val}\n")

            # Ajustar colores a formato 5-6-5
            image[row][col][0] = int(r_val, 2) << 3
            image[row][col][1] = int(g_val, 2) << 2
            image[row][col][2] = int(b_val, 2) << 3

# Guardar imagen modificada
imwrite(output_path, image)

print(f"Archivo generado: {mi_path}")
print(f"Imagen modificada guardada: {output_path}")

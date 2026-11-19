from PIL import Image, ImageDraw

S = 1024
img = Image.new("RGB", (S, S), "#0d0f12")
d = ImageDraw.Draw(img)

# grüner Kopfpunkt
d.ellipse((250, 210, 330, 290), fill="#7cd66b")

# drei Zeilen, unterschiedlich lang
for i, w in enumerate((470, 470, 300)):
    y = 400 + i * 150
    d.rounded_rectangle((250, y, 250 + w, y + 46), radius=23, fill="#e8eaed")
    d.ellipse((250, y - 26, 302, y + 26), fill="#7cd66b")

# dünner Rahmen
d.rounded_rectangle((60, 60, S - 60, S - 60), radius=170, outline="#24282f", width=10)

img.save("C:/Users/Marcel/dev/personal-app/docs/icon-1024.png")
img.resize((512, 512), Image.LANCZOS).save("C:/Users/Marcel/dev/personal-app/docs/icon-512.png")
img.resize((180, 180), Image.LANCZOS).save("C:/Users/Marcel/dev/personal-app/docs/icon-180.png")
print("ok")

# Install packages if needed
# install.packages(c("box", "hexSticker", "magick", "sysfonts", "showtext"))

box::use(
    hexSticker[sticker],
    magick[image_read],
    sysfonts[font_add_google],
    showtext[showtext_auto]
)

# Set up fonts
font_add_google("Open Sans", "open_sans")
showtext_auto()

# Define brand color to match your logo
brand_color <- "#54AC92"

filename <- "man/figures/logo.png"

# Read your logo
img <- image_read("./.graphics/kucoin-logo.png")

# Create hex sticker
sticker <- sticker(
    subplot = img,
    s_x = 1,
    s_y = 1,
    s_width = 1.25,
    s_height = 1.25,

    package = "",
    p_color = brand_color,
    p_size = 20,
    p_family = "open_sans",

    h_fill = "white",
    h_color = "white",

    filename = "man/figures/logo-small.png",
    dpi = 120
)

# Save the sticker
print(sticker)

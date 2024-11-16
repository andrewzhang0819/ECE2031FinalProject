import numpy as np

# Set parameters
num_values = 10000
angle_step = 2 * np.pi / num_values
mem_width = 16

# Generate sine lookup table
sine_lookup_table = [hex(int((num_values/2)*np.sin(i * angle_step)+num_values/2)) for i in range(num_values)]

# Save to file (optional)
with open("sine_lookup_table.mif", "w") as f:
    f.write(f"DEPTH = {num_values};\n\n")

    f.write(f"WIDTH = {mem_width};\n\n")

    f.write(f"ADDRESS_RADIX = HEX;\n")
    f.write(f"DATA_RADIX = HEX;\n\n")

    f.write(f"CONTENT\nBEGIN\n")

    for value in sine_lookup_table:
        value = str(value)
        address = str(hex(sine_lookup_table.index(value)))

        value = value.replace('0x','')
        address = address.replace('0x','')

        while (len(value) < 4):
            value = "0" + value
        while (len(address) < 4):
            address = "0" + address

        f.write(f"{address.upper()}:    {value.upper()};\n")

    f.write(f"END;")

print("Sine lookup table generated with 10,000 values.")

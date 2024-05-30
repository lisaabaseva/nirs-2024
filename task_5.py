from pydicom import dcmread
import matplotlib.pylab as plt


def get_image_information(filepath):
    with open(filepath, 'rb') as infile:
        ds = dcmread(infile)

    arr = ds.pixel_array
    plt.imshow(arr, cmap=plt.cm.bone)

    rows = ds.Rows
    columns = ds.Columns
    print(f"\tШирина изображения: {rows}\n\tВысота изображения: {columns}")

    size = ds.BitsStored
    print("\tРазмер пикселя (бит/пиксель): ", size)

    min_value = arr.min()
    max_value = arr.max()
    print(f"\tМинимальное значение пикселя: {min_value}\n\tМаксимальное значение пикселя: {max_value}")

    # print(f"\nОписание файла: \n{ds}")


def main() -> None:
    for i in range(2, 10):
        print(f"\nИзображение {i}.dcm")
        filepath = f"C:\\Users\\Lisa\\Desktop\\для НИРС\\nirs\\datasets\\{i}.dcm"
        get_image_information(filepath)
        plt.show()


if __name__ == "__main__":
    main()

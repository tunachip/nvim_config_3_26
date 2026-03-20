# tasks/test.py

num1: int = 1
num2: float = 2.3
word1: str = 'wild'
word2: list = ['w', 'i', 'l', 'd']
print(word2)


def print_source(source: str) -> None:
    print(source)


def main():
    for i in range(0, 4):
        print("is", f"'{word1[i]}'", "equal to",
              f"'{word2[i]}'" + "?", end=' ')

        print("yes!" if word1[i] == word2[i] else "no!")


if __name__ == '__main__':
    main()

# test.py

def mstring(text: str, times: int) -> str:
    return text * times


if __name__ == "__main__":
    print(f"""{mstring(
          input("Give me a Word\n> "),
          int(input("Give me a number:\n> "))
          )}""")

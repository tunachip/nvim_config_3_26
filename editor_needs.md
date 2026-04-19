# editor_needs.md
A Description of what a Good Text Editor should do.  


## Encoding Basic info into Non-Textual Presentations


https://github.com/mvllow/modes.nvim


## Dynamic Theme rather than Fixed
Common Conventions are that Syntax Highlights should be static
I can think of at least 2 cases where this should not be true

1. Comments 'loud/quiet'
I think there should be LOUD and QUIET comments.
This already exists in small ways with TODO and similar flags
We should make more use of this by adding flags which encode COMMENT VOLUME
```python
# This is a Normal Comment
def is_len (arg1: str, arg2: int) -> bool:
    return len(arg1) == arg2

"""!
This is a Loud Multiline Comment
"""

"""
! This is a Loud Line in a Multiline Comment

These Lines Here should be normal comment lines
The loud flag in this case is being used as a header
While these lines are used as a details pane
"""

#! This is a Loud Comment
if __name__ == '__main__':
    print(("good" if is_len("the", 3) else "bad"))
```
```typescript
// This is a Comment
function is_len (arg1: string, arg2: number): bool {
  return arg1.length === arg2;
}

/*!
This is a Loud Multiline Comment
*/

/*
! This is a Loud Line in a Multiline Comment

These Lines Here should be normal comment lines
The loud flag in this case is being used as a header
While these lines are used as a details pane
*/

//! This is a Loud Comment
if (is_len("the", 3)) {
  console.log("good");
} else {
  console.log("bad");
}
```
Having 2 Comment Color Volumes should allow users a better experience

2. Highlight by Syntax
we should be able to enter a command like '':hl string yellow' and have all strings be highlighted yellow
it seems so stupid to me that this doesn't already exist
beyond this, it seems stupid that

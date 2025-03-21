# 03-03-2025
# **Python**
## Remove Outermost Parentheses
Given a valid parentheses string (s), remove the outermost parentheses from each primitive group and return the modified string.

```python
def remove_outermost_paranthesis(s):
    result = []
    open_count = 0
    for char in s:
        if char == "(" and open_count > 0:
            result.append(char)
        elif char == ")" and open_count > 1:
            result.append(char)
        if char == '(':
            open_count += 1
        elif char == ')':
            open_count -= 1
    if open_count != 0:
        return "invalid paranthesis"
    return ''.join(result)

print(remove_outermost_paranthesis('(()())'))  # output ‘()()’
print(remove_outermost_paranthesis('(()()'))    # output ‘invalid paranthesis’
```

## Largest Odd Number in String
Given a numeric string s, find the largest-valued odd number that can be obtained by removing some (or no) digits from the end of s. If no odd number exists, return an empty string.

```python
def largest_odd_number(s):
  for i in range(len(s)-1,-1,-1):
    if int(s[i]) % 2 == 1:
      return s[:i+1]
  return ""
 
print(largest_odd_number("51"))	# output ‘51’
print(largest_odd_number("35428"))  	# output ‘35’
```

## Reverse Words in a String
Given a string s containing words separated by spaces, return a new string where the words appear in reverse order, while maintaining a single space between them and removing any leading or trailing spaces.

```python
def reverse_words(s):
    words = [word for word in s.split()]
    return ' '.join(words[::-1])
 
print (reverse_words("the sky is blue"))	# output ‘blue is sky the’
```

## Anagram
Write a function that checks whether two given strings are anagrams of each other.

```python
def anagram(a1, a2):
  return sorted(s1) == sorted(s2)
 
print (is_anagram("listen", "silent")) # output 'True'
print(is_anagram("hello", "world")) # output 'False'
```

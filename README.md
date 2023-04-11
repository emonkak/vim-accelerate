# accelerate

**accelerate** is a Vim plugin to define a special key mapping to accelerate key repeating. For example, to accelerate cursor movements using |hjkl| in Normal and Visual mode:

```vim
call accelerate#map('nv', '', 'h')
call accelerate#map('nv', '', 'j')
call accelerate#map('nv', '', 'k')
call accelerate#map('nv', '', 'l')
```

## Requirements

- Vim 8.0 or later

## Documentation

You can access the [documentation](https://github.com/emonkak/vim-accelerate/blob/master/doc/accelerate.txt) from within Vim using `:help accelerate`.

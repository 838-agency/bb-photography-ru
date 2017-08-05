«О фотографии по-простому» — это перевод книги [The Bastards Book of Photography](http://photography.bastardsbook.com), написанной Дэном Нгуеном.

Оригинальная книга и фотографии распространяются под лицензией Creative Commons Attribution - NonCommercial. Данный перевод распространяется на [тех же условиях](http://creativecommons.org/licenses/by-nc/3.0/us/deed.ru).

Сайт сделан на движке [Jekyll](http://jekyllrb.com/). Также использованы плагины `blockquote.rb` и `titlecase.rb` из старой версии [Octopress](https://github.com/imathis/octopress/) и плагин `custom_image_tag.rb` из [оригинального репозитория](https://github.com/bastards/photography) этой книги.

Тема основана на [Long Haul](https://github.com/brianmaierjr/long-haul), теме для Jekyll, её автор — [@brianmaierjr](https://twitter.com/brianmaier). Подробности можно посмотреть в [THEME.md](THEME.md). Фавиконка — из набора [Open Iconic](https://useiconic.com/open).

Если вы обнаружили ошибку или хотите предложить улучшить что-либо, пожалуйста, используйте для связи раздел Issues.

Не забудьте сходить [в Фликр](https://www.flickr.com/photos/zokuga/) Дэна, там много отличных фотографий, которые не вошли в эту книгу.

#### Как установить локально

На Ubuntu 16.04 сначала нужно поставить системные пакеты:

```
sudo apt-get install ruby ruby-dev exiftool
```

Потом установить зависимости для проекта (находясь в его директории):

```
gem install bundler
bundle install
```

А после этого запускать сервер для разработки через `bundle exec jekyll serve` либо выполнять сборку через `bundle exec jekyll build`.

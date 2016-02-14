---
layout: page
title: Оглавление
---

<div class="table-of-contents">
    <ul class="posts noList">
        {% for post in site.posts reversed %}
        <li>
            <a href="{{ post.url }}">
                <figure class="preview">
                    {% if post.ledeimage %}<img src="{{ site.images_dir }}/preview/{{ post.ledeimage }}" alt="{{ post.title }}">{% endif %}
                    <figcaption>
                        <h4>{{ post.title }}</h4>
                        <p class="description">{% if post.description %}{{ post.description | strip_html | strip_newlines | truncate: 120 }}{% else %}{{ post.content | strip_html | strip_newlines | truncate: 120 }}{% endif %}</p>
                    </figcaption>
                </figure>
            </a>
        </li>
        {% endfor %}
    </ul>
</div>

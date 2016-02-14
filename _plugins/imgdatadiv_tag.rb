# Author: Anton Vasyunin (https://github.com/thevasya)
# License: Public Domain
#
# This script is used to process {% imgdatadiv %} tags in posts. It outputs
# <figure> element with target image, and formatted metadata for that image.
# This script downloads original (source) image file from Flickr, and extracts
# its metadata with the help of mini_exiftool. Metadata is cached to a file, so
# downloading / extracting should only happen once.
#
# Inspiration:
#
# - photo_data.rb from original Bastard's Book repo (https://github.com/bastards/photography/tree/master/plugins/photo_cms)
# - include.rb from Jekyll (https://github.com/jekyll/jekyll)
# - blockquote.rb from Octopress (https://github.com/imathis/octopress)
#
# Example:
#
# {% imgdatadiv bill-cunningham-on-the-street-after-_-6841067449.jpg large %}
#    На улице после парада в честь футбольного клуба New York Giants
# {% endimgdatadiv %}
#
# Result:
#
# <figure class="wide">
#     <img src="/assets/content/images/large/bill-cunningham-on-the-street-after-_-6841067449.jpg" alt="" />
#     <figcaption>
#         <div class="image-meta">
#             <dl>
#                 <dt class="attr">Компенсация экспозиции:</dt>
#                 <dd>-1/3</dd>
#                 <dt class="attr">Выдержка:</dt>
#                 <dd>1/400</dd>
#                 <dt class="attr">Диафрагма:</dt>
#                 <dd>4.5</dd>
#                 <dt class="attr">ISO:</dt>
#                 <dd>400</dd>
#                 <dt class="attr">Фокусное расстояние:</dt>
#                 <dd>19.0 мм</dd>
#                 <dt class="attr">Вспышка:</dt>
#                 <dd>выключена</dd>
#                 <dt class="attr">Снято на</dt>
#                 <dd>Canon EOS 5D Mark II / EF16-35mm f/2.8L II USM</dd>
#             </dl>
#             <a href="https://www.flickr.com/photos/32451477@N02/6841067449">Посмотреть на Фликре</a>
#         </div>
#         <div class="caption">
#             <p>На улице после парада в честь футбольного клуба New York Giants</p>
#         </div>
#     </figcaption>
# </figure>

require 'open-uri'
require 'mini_exiftool'
require 'nokogiri'
require 'json'

module Jekyll

    class ImageDataDivTag < Liquid::Block
        @img = nil
        @img_meta = nil
        @img_meta_alt = nil
        @image_flickr_id = nil

        def initialize(tag_name, fname_arg, tokens)
            super
            @fname_arg = fname_arg.strip
        end

        def get_image_flickr_id(context)
            if d = File.basename(@fname).match(/-_-(\d+)/)
                id = d[1]
                return id
            else
                return nil
            end
        end

        def get_image_flickr_url(context)
            flickr_base_url = 'https://www.flickr.com/photos/32451477@N02/'
            @image_flickr_id = get_image_flickr_id(context)

            if @image_flickr_id
                return flickr_base_url + @image_flickr_id.to_s
            else
                return nil
            end
        end

        def get_original_image_flickr_url(context)
            image_flickr_url = get_image_flickr_url(context)

            if image_flickr_url
                return image_flickr_url + '/sizes/o'
            else
                return nil
            end
        end

        def download_original_image_from_flickr(context)
            original_image_flickr_url = get_original_image_flickr_url(context)
            doc = Nokogiri::HTML(open(original_image_flickr_url))
            source = doc.at_css('#allsizes-photo img').attributes['src']
            if source
                puts 'Downloading from source: ' + source
                File.open(get_resolved_source_image_path(context), 'wb') do |fo|
                    fo.write open(source).read
                end
            end
        end

        def get_image_path(context)
            File.join(context.registers[:site].config['images_dir'], @size, @fname).encode('UTF-8', 'UTF-8', :invalid => :replace)
        end

        def get_images_dir(context)
            context.registers[:site].config['images_dir'].freeze
        end

        def get_resolved_images_dir(context)
            context.registers[:site].in_source_dir(@images_dir)
        end

        def get_resolved_image_path(context)
            File.join(context.registers[:site].in_source_dir(@images_dir), @size, @fname).encode('UTF-8', 'UTF-8', :invalid => :replace)
        end

        def get_source_images_dir(context)
            context.registers[:site].config['source_images_dir'].freeze
        end

        def get_resolved_source_image_path(context)
            if @image_flickr_id
                return File.join(context.registers[:site].in_source_dir(@source_images_dir), @image_flickr_id + '.jpg').encode('UTF-8', 'UTF-8', :invalid => :replace)
            else
                return nil
            end
        end

        def extract_image_metadata(context, image)
            jpeg = MiniExiftool.new(image)
            img_meta = nil

            if jpeg.tags
                img_meta = Hash.new

                img_meta['Exposure compensation:'] = jpeg['ExposureCompensation'].to_s
                img_meta['Shutter speed:'] = jpeg['ShutterSpeed'].to_s
                img_meta['F number:'] = jpeg['FNumber'].to_s
                img_meta['ISO:'] = jpeg['ISO'].to_s
                img_meta['Focal length:'] = jpeg['FocalLength']
                img_meta['Flash used:'] = jpeg['Flash']

                img_meta['Taken with'] = jpeg['Model']
                img_meta['Taken with'] += ' / ' + jpeg['Lens'] if jpeg['Lens']

                img_meta['View on Flickr'] = get_image_flickr_url(context) if get_image_flickr_url(context)
            end

            return img_meta
        end

        def get_localized(string)
            dict = {
                'Exposure compensation' => 'Компенсация экспозиции',
                'Shutter speed' => 'Выдержка',
                'F number' => 'Диафрагма',
                'Focal length' => 'Фокусное расстояние',
                'Flash used' => 'Вспышка',
                'Off, Did not fire' => 'выключена',
                'View on Flickr' => 'Посмотреть на Фликре',
                'Taken with' => 'Снято на'
            }

            @string = string.dup
            dict.each {|k,v| @string.gsub! k, v }
            @string.gsub!(/^(\d+\.\d+\s)(mm)/) { $1 + 'мм' }
            return @string != '' ? @string : '-'
        end

        def get_image_metadata_db_path(context)
            db_filename = 'image_metadata_db'
            File.join(context.registers[:site].in_source_dir(@images_dir), db_filename).encode('UTF-8', 'UTF-8', :invalid => :replace)
        end

        def get_image_metadata(context)
            real_db_filename = get_image_metadata_db_path(context)
            real_source_image_path = get_resolved_source_image_path(context)

            if !File.exist?(real_db_filename)
                puts 'Metadata DB file does not exist, creating it'
            end

            metadata_db_file = File.new(real_db_filename, 'a+')
            metadata_db_json_array = metadata_db_file.each_line.map { |l| JSON.parse(l) }

            metadata_db_json = Hash.new

            metadata_db_json_array.each do |item|
                if item.instance_of? Hash
                    item.each do |k,v|
                        metadata_db_json[k] = v
                    end
                end
            end

            image_metadata = metadata_db_json[@image_flickr_id.to_s]

            if !image_metadata
                if !File.exist?(real_source_image_path)
                    puts 'Source image file does not exist: ' + real_source_image_path
                    download_original_image_from_flickr(context)
                end

                if File.exist?(real_source_image_path)
                    image_metadata = extract_image_metadata(context, real_source_image_path)
                end

                if image_metadata
                    puts 'Writing img meta to DB file for image ' + @image_flickr_id.to_s

                    metadata_db_file.puts(JSON.dump(
                        @image_flickr_id.to_s => image_metadata
                    ))
                end
            end

            return image_metadata
        end

        def render(context)
            if @fname_arg == '__page_ledeimage'
                @fname = context.environments.first['page']['ledeimage']
                @caption = context.environments.first['page']['ledecaption']
                @size = 'large'
                @classnames = 'wide'

                if @caption == nil
                    @caption = super
                end
            else
                @fname, @size, @additional_classname = @fname_arg.strip.split(/ +/)
                @classnames = @size == 'large' ? 'wide' : 'medium'
                @caption = super

                if @additional_classname
                    @classnames += ' ' + @additional_classname
                end
            end

            @img = get_image_path(context)
            @image_flickr_id = get_image_flickr_id(context)

            @images_dir = get_images_dir(context)
            @source_images_dir = get_source_images_dir(context)

            real_img_path = get_resolved_image_path(context)
            @img_meta = get_image_metadata(context)

            if @img and real_img_path
                '<figure class="' + @classnames + '">' +
                    '<img src="' + @img + '" alt="">' +
                    '<figcaption>' +
                        '<div class="image-meta">' +
                            '<dl>' +
                                if @img_meta then @img_meta.collect {|k,v| '<dt class="attr">' + get_localized(k) + '</dt><dd>' + get_localized(v) + '</dd>' if v and k != "View on Flickr"}.join(' ')
                                else '' end +
                            '</dl>' +
                            if @img_meta and @img_meta['View on Flickr'] then '<a href="' + @img_meta["View on Flickr"] + '">' + get_localized('View on Flickr') + '</a>' else '' end +
                        '</div>' +
                        if @caption and @caption != '' then '<div class="caption"><p>' + @caption + '</p></div>' else '' end +
                    '</figcaption>' +
                '</figure>'
            else
                'Error processing input.'
            end
        end
    end
end

Liquid::Template.register_tag('imgdatadiv', Jekyll::ImageDataDivTag)

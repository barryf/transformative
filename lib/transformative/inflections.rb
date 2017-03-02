# add irregular plural for responses to handle u-responses mf2 class
# which breaks the #to_hash method in the microformats2 gem...
# basically needed to work with @voxpelli's site!
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'responses', 'responsi'
end

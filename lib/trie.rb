require 'set'
class Trie
  attr_accessor :children, :value, :final

  def initialize(value=nil)
    @children = {}
    @value = value
    @final = false
  end

  def add(char)
    @children[char] ||= Trie.new( @value.to_s + char)
  end

  def insert(word)
    node = self
    for char in word.chars
      node.add(char)
      node = node.children[char]
    end
    node.final = true
  end

  def find(word)
    node = self
    for char in word.chars
      node = node.children[char] or return
    end
    node.value
  end

  def all_prefixes
    results = Set.new
    results.add(@value) if @final
    return results if @children.empty?
    @children.values.map(&:all_prefixes).inject(results, &:+)
  end

  def autocomplete(prefix)
    node = self
    for char in prefix.chars
      node = node.children[char] or return Set.new
    end
    node.all_prefixes
  end
end

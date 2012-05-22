#!/usr/bin/env ruby
# based on python program By Steve Hanov, 2011. Released to the public domain.

DICTIONARY = "/usr/share/dict/words"
QUERY = ARGV[1..-1] || []

# This class represents a node in the directed acyclic word graph (DAWG). It
# has a list of edges to other nodes. It has functions for testing whether it
# is equivalent to another node. Nodes are equivalent if they have identical
# edges, and each identical edge leads to identical states. The __hash__ and
# __eq__ functions allow it to be used as a key in a python dictionary.
class DawgNode
  @@next_id = 0

  attr_reader :id, :edges
  attr_accessor :final

  def initialize
    @id = @@next_id
    @@next_id += 1
    @final = false
    @edges = {}
  end

  def to_s
    arr = [ @final ? 1 : 0 ]

    for label, node in @edges
      arr << label
      arr << node.id.to_s
    end

    arr.join('_')
    end

  def hash
    to_s.hash
  end

  def eql?(other)
    to_s == other.to_s
  end

end

class Dawg
  def initialize
    @previous_word = ""
    @root = DawgNode.new

    # Here is a list of nodes that have not been checked for duplication.
    @unchecked_nodes = []

    # Here is a list of unique nodes that have been checked for
    # duplication.
    @minimized_nodes = {}
  end

  def insert( word )
    if word < @previous_word
      raise "Words must be inserted in alphabetical order."
    end

    # find common prefix between word and previous word
    common_prefix = 0
    [word.size, @previous_word.size].min.times do |i|
      break if word[i] != @previous_word[i]
      common_prefix += 1
    end

    # Check the uncheckedNodes for redundant nodes, proceeding from last
    # one down to the common prefix size. Then truncate the list at that
    # point.
    minimize( common_prefix )

    # add the suffix, starting from the correct node mid-way through the
    # graph
    if @unchecked_nodes.empty?
      node = @root
    else
      node = @unchecked_nodes[-1][2]
    end

    for letter in word[common_prefix..-1].chars
      next_node = DawgNode.new
      node.edges[letter] = next_node
      @unchecked_nodes << [node, letter, next_node]
      node = next_node
    end

    node.final = true
    @previous_word = word
  end

  def finish
    # minimize all uncheckedNodes
    minimize( 0 )
  end

  def minimize( down_to )
    # proceed from the leaf up to a certain point
    for i in (@unchecked_nodes.size - 1).downto(down_to)
      parent, letter, child = @unchecked_nodes[i]
      if @minimized_nodes.include?(child)
        # replace the child with the previously encountered one
        parent.edges[letter] = @minimized_nodes[child]
      else
        # add the state to the minimized nodes.
        @minimized_nodes[child] = child
      end
      @unchecked_nodes.pop
    end
  end

  def lookup( word )
    node = @root
    for letter in word.chars
      return unless node.edges.has_key?(letter)
      node = node.edges[letter]
    end
    node.final
  end

  def node_count
    @minimized_nodes.size
  end

  def edge_count
    count = 0
    for node in @minimized_nodes
      count += node.edges.size
    end
    count
  end
end


dawg = Dawg.new
words = File.read(DICTIONARY).split.sort
word_count = 0

start = Time.now
for word in words
  word_count += 1
  dawg.insert(word)
  if word_count.modulo(100).zero?
    print "%d\r" % word_count
  end
end
dawg.finish
print "Dawg creation took %g s" % (Time.now-start)

edge_count = dawg.edge_count
print "Read %d words into %d nodes and %d edges" % [ word_count, dawg.node_count, edge_count ]
print "This could be stored in as little as %d bytes" % edge_count * 4

for word in QUERY
  if dawg.lookup( word )
    puts "#{word} is in the dictionary."
  else
    puts "#{word} not in dictionary."
  end
end

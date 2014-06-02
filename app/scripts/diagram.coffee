class @Diagram
  constructor: (diagram, schema = {}) ->
    @title = diagram.props.title
    @concepts = diagram.concept
    @edges = diagram.edge
    @schema = schema
  display: () ->
    @drawEdges()
    @drawConcepts()
    @drawLabels()

class @TJ04Diagram extends Diagram
  drawEdges: () ->
  drawConcepts: () ->


class @TJ10Diagram extends Diagram
  constructor: (diagram, schema = {}) ->
    @title = diagram.props.title
    @concepts = _.map(diagram.node, (n) ->
      n.objectContingent = n.concept.objectContingent
      n.attributeContingent = n.concept.attributeContingent
      return n
    )
    @edges = diagram.edge
    @schema = schema
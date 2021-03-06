
App.TJ04SchemaParser = Ember.Object.extend(
  extractAllObjects: (schema) ->
    return schema.context.object

  extractAllAttributes: (schema) ->
    return schema.context.attribute
)

App.TJ10SchemaParser =
  extractAllAttributes: (schema) ->
    attributes = []
    _.each(schema.diagrams, (diagram) ->
      _.each(diagram.node, (n) ->
        attr = _.map(n.attributeContingent.attribute, (o) -> o["#text"])
        attributes = _.union(attributes, attr)
      )
    )
    return attributes

  extractObjects: (node) ->
    #console.log node
    _.compact(_.map(node.concept.objectContingent.object, (o) -> o["#text"]))

  extractAllObjects: (schema) ->
    objects = []

    _.each(schema.diagrams, (diagram) =>
      _.each(diagram.node, (n) =>
        obj = @extractObjects(n)
        objects = _.union(objects, obj)
      )
    )
    #console.log objects
    return objects

  parseLabelInfo: (label = {}) ->
    labelInfo =
      offset:
        x: parseFloat label.offset?.x ? 0, 10
        y: parseFloat label.offset?.y ? 0, 10
      bgColor: label.backgroundColor?['#text'].convertToRGBA() ? "#fff"
      textColor: label.textColor?['#text'].convertToRGBA() ? "#000"
      textAlignment: label.textAlignment?['#text'] ? "middle"

  extractVisualInfo: (node) ->
    visual =
      position:
        x: parseFloat(node.position.x, 10)
        y: parseFloat(node.position.y, 10)
      objectLabel: @parseLabelInfo node.objectLabelStyle
      attributeLabel:@parseLabelInfo node.attributeLabelStyle

  createAttributeOrObject: (type, obj, store) ->
    all = store.all type
    found = all.findBy('value', obj)
    unless found
      store.createRecord type,
        id: _.uniqueId(type)
        value: obj
    else found

  extractDiagram: (d, i) ->
    diagram = @store.findByIdOrCreate('diagram', i,
      id: _.uniqueId('dia')
      title: d._title
    )

    unless diagram.get 'parsed'
      diagram.set 'parsed', true

      concepts = _.map d.node, (n) =>
        concept = @store.createRecord('concept_node',
        id: _.uniqueId('node')
        inDiagramId: n._id
        position:
          x: parseFloat n.position._x, 10
          y: parseFloat n.position._y, 10
        )

        if Ember.isArray n.concept.attributeContingent.attribute
          attributes = _.map n.concept.attributeContingent.attribute, (a) =>
            attribute = @createAttributeOrObject 'attribute', a, @store
        else
          attributes = []
          if _.isObject  n.concept.attributeContingent
            attribute = @createAttributeOrObject 'attribute', n.concept.attributeContingent.attribute, @store
            attributes.push attribute

        #console.log attributes
        concept.get('attributes').pushObjects attributes

        if Ember.isArray n.concept.objectContingent.object
          objects = _.map n.concept.objectContingent.object, (o) =>
            @createAttributeOrObject 'object', o, @store
        else
          objects = []
          if _.isObject n.concept.objectContingent
            object = @createAttributeOrObject 'object', n.concept.objectContingent.object, @store
            objects.push object

        concept.get('objects').pushObjects objects

        if n.attributeLabelStyle
          attributeLabel = @store.createRecord 'label_info',
            id: _.uniqueId('label')
            offset:
              x: parseInt n.attributeLabelStyle.offset._x, 10
              y: parseInt n.attributeLabelStyle.offset._y, 10
            bgColor: n.attributeLabelStyle.backgroundColor.convertToRGBA()
            textColor: n.attributeLabelStyle.textColor.convertToRGBA()
            textAlignment: n.attributeLabelStyle.textAlignment
          concept.set('attributeLabel', attributeLabel)

        if n.objectLabelStyle
          objectLabel = @store.createRecord 'label_info',
            id: _.uniqueId('label')
            offset:
              x: parseInt n.objectLabelStyle.offset._x, 10
              y: parseInt n.objectLabelStyle.offset._y, 10
            bgColor: n.objectLabelStyle.backgroundColor.convertToRGBA()
            textColor: n.objectLabelStyle.textColor.convertToRGBA()
            textAlignment: n.objectLabelStyle.textAlignment
          concept.set('objectLabel', objectLabel)

        return concept

      diagram.get('concepts').pushObjects concepts

      edges = _.map d.edge, (e) =>
        edge = @store.createRecord('edge',
          id: _.uniqueId("edge")
        )
        inboundNode = diagram.get('concepts').findBy('inDiagramId', e._to)
        outboundNode = diagram.get('concepts').findBy('inDiagramId', e._from)
        edge.set 'to', inboundNode
        edge.set 'from', outboundNode
        edge.set 'diagram', diagram
        inboundNode.get('inboundEdges').pushObject edge
        outboundNode.get('outboundEdges').pushObject edge

        return edge

      diagram.get('edges').pushObjects edges
    return diagram


  extractDiagrams: (schema, schemaName) ->
    return _.map schema.diagram, @extractDiagram

  extractDiagramNames: (schema, schemaName) ->

    @store.unloadAll('diagram')
    diagrams = _.map schema.diagram, (d, i) =>
      @store.createRecord 'diagram',
        id: _.uniqueId('dia')
        title: d._title

App.ContextParser = Ember.Object.extend(
  parsers:
    'TJ0.4': App.TJ04SchemaParser
    'TJ1.0': App.TJ10SchemaParser

  #cursory means the parser just extracts diagram names and database information (if it exists)
  parse: (schema, version, store, schemaName, cursory = true) ->
    @parser = @parsers[version]
    result = store.createRecord 'conceptual_schema',
      name: schemaName
      version: version
    @parser.store = store
    if cursory
      diagrams = @parser.extractDiagramNames(schema, schemaName)
    else
      diagrams = @parser.extractDiagrams(schema, schemaName)
    console.log 'finished parsing'
    result.get('diagrams').pushObjects diagrams
    return result

  parseSingleDiagram: (schema, title, id) ->
    console.log schema, title, schema.diagram.findBy('_title', title)
    return @parser.extractDiagram(schema.diagram.findBy('_title', title), id)
)

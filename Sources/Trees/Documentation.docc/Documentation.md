# ``TreeCore``

## Overview

``TreeCore`` defines ``Tree``,  a structure for representing navigation hierarchies, and ``UnificationContext``, which ‘diffs’ (or more precisely ’unifies’) a desired ``Tree`` with a current ``Tree``.

## Topics

### Trees

- ``Tree``
- ``TreeProtocol``
- ``KindProtocol``

### Blueprints

- ``Blueprint``
- ``BlueprintProtocol``
- ``CompleteBlueprint``

### Leafs

- ``LeafBlueprint``
- ``LeafNode``

### Presentations

- ``PresentationBlueprint``
- ``CompletePresentationBlueprint``
- ``PresentationNode``
- ``PresentationTiming``

### Tabs

- ``TabsBlueprint``
- ``TabsNode``
- ``TabIndex``

### Tree Traversal

- ``Zipper``
- ``PathElement``

### Unification

- ``UnificationContext``

### Mutations

- ``Mutation``
- ``PushPathMutation``
- ``PopPathMutation``
- ``PresentMutation``
- ``DismissMutation``
- ``ReplaceMutation``

### Presentation Styles

- ``PresentationStyle``
- ``PresentationStyleSlice``
- ``EitherSlice``

### Slab Styles

- ``SlabStyle``
- ``SlabStyles``
- ``PresentationContext``

- ``AssociativeOperation``
- ``Associative``

- ``BlurOperation``
- ``CornerRadiusOperation``
- ``IsInteractiveOperation``
- ``OffsetOperation``
- ``OpacityOperation``

### Utilities

- ``AlwaysEqual``
- ``Empty``

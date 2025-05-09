//
//  File.swift
//  
//
//  Created by Miguel de Icaza on 9/25/23.
//

#if !(os(Windows) && swift(<5.9.1))

/// Creates the definition for a Swift class to be surfaced to Godot.
///
/// This macro creates the required constructors that the SwiftGodot framework requires (the `init`, and the
/// `init(nativeHandle:)`) , ensures that both of those initialize the class if required, and registers
/// any `@Export` and `@Callable` methods for the class effectively surfacing properties and
/// methods to godot
///
/// - Parameter behavior: using `.tool` value makes the overridden methods like `_ready` or
/// `_process` run in editor, making the class work like `@tool` annotated script in GDScript
///
@attached(member,
          names: named (_initializeClass), named(classInitializer), named (implementedOverrides))
public macro Godot(_ behavior: ClassBehavior = .gameplay) = #externalMacro(module: "SwiftGodotMacroLibrary", type: "GodotMacro")

public enum ClassBehavior: Int {
    case gameplay, tool
}

/// Exposes the function to the Godot runtime
///
/// When this attribute is applied to a function, the function is exposed to the Godot engine, and it
/// can be called by scripts in other languages.
///
/// The parameters and returns type of the function must be `_GodotBridgeable`.
///
/// - Parameter autoSnakeCase: if `true` (default value is `false`), the function name will be automatically translated from `camelCase` to `snake_case` when exposed to Godot
@attached(peer, names: prefixed(_mproxy_))
public macro Callable(autoSnakeCase: Bool = false) = #externalMacro(module: "SwiftGodotMacroLibrary", type: "GodotCallable")

/// Exposes a property or variable to the Godot runtime
///
/// When this attribute is applied to a variable or a computer property in a class, the values can be surfaced to the
/// Godot editor and can participate in Godot's serialization process.
///
/// The attribute can only be applied to properties and variables that can be stored in a Variant.
///
/// - Parameter hint: this is of type ``PropertyHint`` and can be used to tell the Godot editor the
/// kind of user interface experience to provide for this.  For example, a string can be a plain string, or a
/// multi-line property box, or it can represent a file.   This hint drives the experience in the editor
/// - Parameter hintStr: some of the hint types can use an additional configuration option as a string
/// and this is used for this.  For example the `.file` option can have a mask to select files, for example `"*.png"`
/// - Parameter usage: The desired usage flags, applies to exported variables
///
@attached(peer, names: prefixed(_mproxy_get_), prefixed(_mproxy_set_), arbitrary)
public macro Export(_ hint: PropertyHint = .none, _ hintStr: String? = nil, usage: PropertyUsageFlags = .default) = #externalMacro(module: "SwiftGodotMacroLibrary", type: "GodotExport")

// MARK: - Freestanding Macros

/// A macro used to add a group to exported properties
///
/// For example:
/// ```swift
/// @Godot
/// class Vehicle: Sprite2D {
///     #exportGroup("VIN")
///     @Export
///     var vin: String = "0123456789ABCDEF0"
///     #exportGroup("YMM", prefix: "ymms_")
///     @Export
///     var ymms_year: Int = 0
///     @Export
///     var ymms_make: String = "Make"
///     @Export
///     var ymms_model: String = "Model"
/// }
/// ```
///
/// - Parameter name: The name of the group.
/// - Parameter prefix: The optional prefix of the group which can be used to only group properties with the specified prefix.
@freestanding(expression)
public macro exportGroup(_ name: String, prefix: String = "") = #externalMacro(module: "SwiftGodotMacroLibrary", type: "GodotMacroExportGroup")

/// A macro used to add a subgroup to exported properties
///
/// For example:
/// ```swift
/// @Godot
/// class Vehicle: Sprite2D {
///     #exportGroup("Vehicle")
///     #exportSubgroup("VIN")
///     @Export
///     var vin: String = "0123456789ABCDEF0"
///     #exportSubgroup("YMM", prefix: "ymms_")
///     @Export
///     var ymms_year: Int = 0
///     @Export
///     var ymms_make: String = "Make"
///     @Export
///     var ymms_model: String = "Model"
/// }
/// ```
///
/// - Parameter name: The name of the subgroup.
/// - Parameter prefix: The optional prefix of the subgroup which can be used to only group properties with the specified prefix.
@freestanding(expression)
public macro exportSubgroup(_ name: String, prefix: String = "") = #externalMacro(module: "SwiftGodotMacroLibrary", type: "GodotMacroExportSubgroup")

/// A macro used to write an entrypoint for a Godot extension and register scene types.
///
/// For example, to initialize a Swift extension to Godot with custom types:
/// ```swift
/// class MySprite: Sprite2D { ... }
/// class MyControl: Control { ... }
///
/// #initSwiftExtension(cdecl: "myextension_entry_point",
///                     types: [MySprite.self, MyControl.self])
/// ```
///
/// - Parameter cdecl: The name of the entrypoint exposed to C.
/// - Parameter types: The node types that should be registered with Godot.
@freestanding(declaration, names: named(enterExtension))
public macro initSwiftExtension(cdecl: String,
                                types: [Wrapped.Type] = []) = #externalMacro(module: "SwiftGodotMacroLibrary",
                                                                        type: "InitSwiftExtensionMacro")

/// Macro used to write an entrypoint for a Godot extension and register all the supported scene types.
///
/// When Godot initializes your extension it does so in stages and you get
/// a chance to register the types that you want to expose to the Godot engine for
/// each stage (``GDExtension/InitializationLevel``).
///
/// For example, to initialize a Swift extension to Godot with some custom types
/// to use in the editor, and some other types to use on the scene.
///
/// ```swift
/// class MySprite: Sprite2D { ... }
/// class MyControl: Control { ... }
///
/// #initSwiftExtension(cdecl: "myextension_entry_point",
///                     editorTypes: [MyEditorPlugin.self],  
///                     sceneTypes: [MySprite.self, MyControl.self])
/// ```
///
/// - Parameter cdecl: The name of the entrypoint exposed to C.
/// - Parameter coreTypes: Types registered at the `.core` level
/// - Parameter editorTypes: Types registered at the `.editor` level
/// - Parameter sceneTypes: Types registered at the `.scene` level
/// - Parameter serverTypes: Types registered at the `.server` level
@freestanding(declaration, names: named(enterExtension))
public macro initSwiftExtension(
    cdecl: String,
    coreTypes: [Object.Type] = [],
    editorTypes: [Object.Type] = [],
    sceneTypes: [Object.Type] = [],
    serverTypes: [Object.Type] = []
) = #externalMacro(
    module: "SwiftGodotMacroLibrary",
    type: "InitSwiftExtensionMacro")

/// A macro that instantiates a `Texture2D` from a specified resource path. If the texture cannot be created, a
/// `preconditionFailure` will be thrown.
///
/// Use this to quickly instantiate a `Texture2D`:
/// ```swift
/// func makeSprite() -> Sprite2D {
///     let sprite = Sprite2D()
///     sprite.texture = #texture2DLiteral("res://assets/playersprite.png")
/// }
/// ```
@freestanding(expression)
public macro texture2DLiteral(_ path: String) -> Texture2D = #externalMacro(module: "SwiftGodotMacroLibrary",
                                                                            type: "Texture2DLiteralMacro")

// MARK: - Attached Macros

/// A macro that enables an enumeration to be visible to the Godot editor.
///
/// Use this macro with `ClassInfo.registerEnum` to register this enumeration's visibility in the Godot editor.
///
/// ```swift
/// @PickerNameProvider
/// enum PlayerClass: Int {
///     case barbarian
///     case mage
///     case wizard
/// }
/// ```
///
/// - Important: The enumeration should have an `Int` backing to allow being represented as an integer value by Godot.
@attached(extension, conformances: CaseIterable, Nameable, names: named(name))
//@attached(member, names: named(name))
public macro PickerNameProvider() = #externalMacro(module: "SwiftGodotMacroLibrary", type: "PickerNameProviderMacro")


/// Low-level: A macro that automatically implements `init(nativeHandle:)` for nodes.
///
/// Use this for a class that has a required initializer with an `UnsafeRawPointer`.
///
/// ```swift
/// @NativeHandleDiscarding
/// class MySprite: Sprite2D {
///     ...
/// }
/// ```
@attached(member, names: named(init(nativeHandle:)))
public macro NativeHandleDiscarding() = #externalMacro(module: "SwiftGodotMacroLibrary",
                                                       type: "NativeHandleDiscardingMacro")

/// A macro that finds and assigns a node from the scene tree to a stored property.
///
/// Use this to quickly assign a stored property to a node in the scene tree.
/// ```swift
/// class MyNode: Node2D {
///     @SceneTree(path: "Entities/Player")
///     var player: CharacterBody2D?
/// }
/// ```
///
/// The generated property will be computed, and therefore read-only.
@attached(accessor)
public macro SceneTree(path: String? = nil) = #externalMacro(module: "SwiftGodotMacroLibrary", type: "SceneTreeMacro")

/// A macro that finds and assigns a node from the scene tree to a stored property.
///
/// Use this to quickly assign a stored property to a node in the scene tree.
/// ```swift
/// class MyNode: Node2D {
///     @Node("Entities/Player")
///     var player: CharacterBody2D
/// }
/// ```
///
/// If you declare the property as optional, the property will be `nil` if the node is missing.
/// If you declare the property as non-optional, or forced-unwrap, it will be a runtime error for the node to be missing.
/// 
/// The generated property will be computed, and therefore read-only.
@attached(accessor)
public macro Node(_ path: String? = nil) = #externalMacro(module: "SwiftGodotMacroLibrary", type: "SceneTreeMacro")


/// Defines a Godot signal on a class.
///
/// The `@Godot` macro will register any #signal defined signals so that they can be used in the editor.
///
/// Usage:
/// ```swift
/// @Godot class MyNode: Node2D {
///     #signal("game_started")
///     #signal("lives_changed", argument: ["new_lives_count", Int.self])
///
///     func startGame() {
///        emit(MyNode.gameStarted)
///        emit(MyNode.livesChanged, 5)
///     }
/// }
/// ```
///
/// - Parameter signalName: The name of the signal as registered to Godot.
/// - Parameter arguments: If the signal has arguments, they should be defined here as a dictionary of argument name to type. For
/// example, ["name" : String.self] declares that the signal takes one argument of string type. The argument name is provided to the godot
/// editor. Argument types are enforced on the `emit(signal:_argument)` method. Argument types must conform to GodotVariant.
@freestanding(declaration, names: arbitrary)
@available(*, deprecated, message: "Use the @Signal macro instead.")
public macro signal(_ signalName: String, arguments: Dictionary<String, Any.Type> = [:]) = #externalMacro(module: "SwiftGodotMacroLibrary", type: "SignalMacro")

/// Defines a Godot signal on a class.
///
/// The `@Godot` macro will register any #signal defined signals so that they can be used in the editor.
///
/// Usage:
/// ```swift
/// @Godot class MyNode: Node2D {
///     @Signal var gameStarted: SimpleSignal
///     @Signal var livesChanged: SignalWithArguments<Int>
///
///     func startGame() {
///        gameStarted.emit()
///        livesChanged.emit(5)
///     }
/// }
/// ```

@attached(accessor)
public macro Signal() = #externalMacro(module: "SwiftGodotMacroLibrary", type: "SignalAttachmentMacro")


#endif

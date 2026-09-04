// The food database the app ships with, quoted per 100 g.
//
// NOT YET SOURCED. Read this before trusting a number here.
//
// These figures are commonly published composition values, written from
// general knowledge rather than transcribed from a table anybody opened. They
// are not verified against ARGENFOODS (Universidad Nacional de Luján, Tabla de
// Composición de Alimentos) or USDA FoodData Central, which are the two
// references this list should be checked against — the first for what is
// actually eaten in Argentina, the second for generic items no national table
// describes any differently, because an apple is an apple.
//
// The staples are the safe end: an apple, an egg, a litre of oil and a kilo of
// sugar are measured objects and these numbers match what every table says. The
// composed dishes are the loose end: milanesa, locro, empanada and pastel de
// papa are estimates by construction, and nobody has checked them against a
// published figure.
//
// Citing a source nobody read would give a reader confidence that was never
// earned, and for food data that matters. So this says what it is instead.
// Replacing it with sourced figures is a pass of its own, still open.
//
// Every figure is a reference value for a GENERIC preparation, not a brand and
// not a recipe. A milanesa is not a controlled object: the breadcrumb, the cut
// and the oil all move, so what is quoted here is the typical composition of
// the typical one. Composed dishes — locro, empanada, pastel de papa — carry
// more of that uncertainty than a raw ingredient does. The figures are rounded
// to whole numbers on purpose: a decimal place would claim a precision the
// source does not have, and the user is weighing on a kitchen scale.
//
// This is a starting point, not an authority. Anything here can be corrected
// or deleted, and the user's own foods sit in the same table alongside it.
//
// Foods deliberately left out rather than guessed:
//   - Submarino. It is milk plus whatever chocolate bar was in the cupboard;
//     its composition is the bar's, and no reference table has an entry for
//     the drink.
//   - Yerba mate as leaves. Nobody eats 100 g of yerba, so a per-100 g figure
//     for the dry leaf is a number with no meaning at the plate. The brewed
//     infusion is here instead, which is what actually gets drunk.

/// One food as it ships: a name, and what 100 g of it is made of.
///
/// A record rather than a class because it is data and nothing else — it has
/// no behaviour to protect and no invariant the domain does not already
/// enforce when the row is read back as a `Food`.
typedef SeedFood = ({
  String name,
  int calories,
  int protein,
  int carbs,
  int fat,
});

/// The catalogue, in the order it happens to be written. Nothing reads this
/// order: the picker sorts by name, because a list this long is searched
/// and scanned alphabetically, never browsed in insertion order.
const argentineFoodSeed = <SeedFood>[
  // Carnes y parrilla
  (name: 'Asado de tira', calories: 290, protein: 25, carbs: 0, fat: 21),
  (name: 'Bife de chorizo', calories: 250, protein: 27, carbs: 0, fat: 16),
  (name: 'Vacío', calories: 230, protein: 27, carbs: 0, fat: 13),
  (name: 'Matambre', calories: 250, protein: 18, carbs: 2, fat: 19),
  (name: 'Carne picada', calories: 250, protein: 17, carbs: 0, fat: 20),
  (name: 'Chorizo', calories: 340, protein: 15, carbs: 2, fat: 30),
  (name: 'Morcilla', calories: 380, protein: 15, carbs: 3, fat: 34),
  (name: 'Pollo, pechuga', calories: 165, protein: 31, carbs: 0, fat: 4),
  (name: 'Pollo, muslo', calories: 210, protein: 26, carbs: 0, fat: 11),
  (name: 'Jamón cocido', calories: 145, protein: 18, carbs: 2, fat: 7),
  (name: 'Salame', calories: 400, protein: 22, carbs: 2, fat: 34),
  (name: 'Merluza', calories: 90, protein: 19, carbs: 0, fat: 1),
  (name: 'Atún al natural', calories: 116, protein: 26, carbs: 0, fat: 1),

  // Platos
  (name: 'Milanesa de carne', calories: 280, protein: 20, carbs: 15, fat: 15),
  (name: 'Milanesa de pollo', calories: 250, protein: 22, carbs: 15, fat: 11),
  (name: 'Empanada de carne', calories: 270, protein: 10, carbs: 27, fat: 13),
  (name: 'Choripán', calories: 300, protein: 12, carbs: 25, fat: 17),
  (name: 'Provoleta', calories: 390, protein: 26, carbs: 2, fat: 31),
  (name: 'Locro', calories: 120, protein: 7, carbs: 13, fat: 4),
  (name: 'Pastel de papa', calories: 130, protein: 8, carbs: 12, fat: 5),
  (name: 'Ñoquis de papa', calories: 135, protein: 4, carbs: 26, fat: 2),
  (name: 'Polenta', calories: 85, protein: 2, carbs: 18, fat: 0),
  (name: 'Pizza de muzzarella', calories: 270, protein: 11, carbs: 33, fat: 10),
  (name: 'Chimichurri', calories: 230, protein: 1, carbs: 4, fat: 24),

  // Panadería y facturas
  (name: 'Pan francés', calories: 270, protein: 9, carbs: 55, fat: 1),
  (name: 'Pan lactal', calories: 265, protein: 8, carbs: 49, fat: 3),
  (name: 'Medialuna', calories: 400, protein: 7, carbs: 45, fat: 21),
  (name: 'Factura rellena', calories: 390, protein: 7, carbs: 48, fat: 19),
  (name: 'Criollitos', calories: 450, protein: 8, carbs: 60, fat: 20),
  (name: 'Galletitas de agua', calories: 420, protein: 10, carbs: 72, fat: 10),

  // Lácteos
  (name: 'Leche entera', calories: 61, protein: 3, carbs: 5, fat: 3),
  (name: 'Leche descremada', calories: 35, protein: 3, carbs: 5, fat: 0),
  (name: 'Yogur entero', calories: 61, protein: 4, carbs: 5, fat: 3),
  (name: 'Yogur descremado', calories: 40, protein: 4, carbs: 6, fat: 0),
  (name: 'Queso cremoso', calories: 300, protein: 20, carbs: 2, fat: 24),
  (name: 'Queso port salut', calories: 330, protein: 22, carbs: 2, fat: 26),
  (name: 'Queso rallado', calories: 400, protein: 33, carbs: 4, fat: 28),
  (name: 'Ricota', calories: 174, protein: 11, carbs: 3, fat: 13),
  (name: 'Manteca', calories: 717, protein: 1, carbs: 0, fat: 81),
  (name: 'Huevo', calories: 145, protein: 13, carbs: 1, fat: 10),

  // Almacén
  (name: 'Arroz blanco, cocido', calories: 130, protein: 3, carbs: 28, fat: 0),
  (name: 'Fideos, cocidos', calories: 155, protein: 6, carbs: 30, fat: 1),
  (name: 'Harina de trigo', calories: 364, protein: 10, carbs: 76, fat: 1),
  (name: 'Avena', calories: 380, protein: 13, carbs: 67, fat: 7),
  (name: 'Lentejas, cocidas', calories: 116, protein: 9, carbs: 20, fat: 0),
  (name: 'Porotos, cocidos', calories: 130, protein: 9, carbs: 24, fat: 1),
  (name: 'Garbanzos, cocidos', calories: 164, protein: 9, carbs: 27, fat: 3),
  (name: 'Aceite de girasol', calories: 884, protein: 0, carbs: 0, fat: 100),
  (name: 'Aceite de oliva', calories: 884, protein: 0, carbs: 0, fat: 100),
  (name: 'Azúcar', calories: 387, protein: 0, carbs: 100, fat: 0),
  (name: 'Miel', calories: 304, protein: 0, carbs: 82, fat: 0),
  (name: 'Maní tostado', calories: 585, protein: 26, carbs: 16, fat: 50),
  (name: 'Nueces', calories: 654, protein: 15, carbs: 14, fat: 65),

  // Verduras y frutas
  (name: 'Papa, hervida', calories: 87, protein: 2, carbs: 20, fat: 0),
  (name: 'Papas fritas', calories: 310, protein: 4, carbs: 41, fat: 15),
  (name: 'Batata, hervida', calories: 76, protein: 1, carbs: 18, fat: 0),
  (name: 'Zapallo', calories: 26, protein: 1, carbs: 7, fat: 0),
  (name: 'Zanahoria', calories: 41, protein: 1, carbs: 10, fat: 0),
  (name: 'Tomate', calories: 18, protein: 1, carbs: 4, fat: 0),
  (name: 'Lechuga', calories: 15, protein: 1, carbs: 3, fat: 0),
  (name: 'Cebolla', calories: 40, protein: 1, carbs: 9, fat: 0),
  (name: 'Choclo', calories: 86, protein: 3, carbs: 19, fat: 1),
  (name: 'Arvejas', calories: 81, protein: 5, carbs: 14, fat: 0),
  (name: 'Palta', calories: 160, protein: 2, carbs: 9, fat: 15),
  (name: 'Banana', calories: 89, protein: 1, carbs: 23, fat: 0),
  (name: 'Manzana', calories: 52, protein: 0, carbs: 14, fat: 0),
  (name: 'Naranja', calories: 47, protein: 1, carbs: 12, fat: 0),
  (name: 'Pera', calories: 57, protein: 0, carbs: 15, fat: 0),
  (name: 'Uva', calories: 69, protein: 1, carbs: 18, fat: 0),
  (name: 'Frutilla', calories: 32, protein: 1, carbs: 8, fat: 0),

  // Dulces
  (name: 'Dulce de leche', calories: 315, protein: 7, carbs: 55, fat: 7),
  (
    name: 'Alfajor de dulce de leche',
    calories: 420,
    protein: 5,
    carbs: 60,
    fat: 18,
  ),
  (name: 'Dulce de batata', calories: 250, protein: 0, carbs: 62, fat: 0),
  (name: 'Mermelada', calories: 250, protein: 0, carbs: 62, fat: 0),
  (name: 'Chocolate con leche', calories: 535, protein: 8, carbs: 59, fat: 30),
  (name: 'Helado de crema', calories: 200, protein: 4, carbs: 24, fat: 10),

  // Bebidas
  (name: 'Mate, infusión', calories: 0, protein: 0, carbs: 0, fat: 0),
  (name: 'Gaseosa cola', calories: 42, protein: 0, carbs: 11, fat: 0),
  (name: 'Cerveza', calories: 43, protein: 0, carbs: 4, fat: 0),
  (name: 'Vino tinto', calories: 85, protein: 0, carbs: 3, fat: 0),
];

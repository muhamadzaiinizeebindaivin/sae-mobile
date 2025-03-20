// Classe Restaurant pour gérer les données
class Restaurant {
  final String name;
  final String cuisine;
  final double rating;
  final int stars; // Nombre d'étoiles (1-5)
  final String imageUrl; // URL de l'image

  Restaurant({
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.stars,
    required this.imageUrl,
  });
}
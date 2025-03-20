import 'package:flutter/material.dart';
import 'restaurant.dart';


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Liste de restaurants fictifs
    List<Restaurant> popularRestaurants = [
      Restaurant(
        name: 'Le Gourmet',
        cuisine: 'Française',
        rating: 4.5,
        stars: 3,
        imageUrl: 'assets/images/image.png',
      ),
      Restaurant(
        name: 'Sushi Zen',
        cuisine: 'Japonaise',
        rating: 4.8,
        stars: 4,
        imageUrl: 'assets/images/image.png',
      ),
      Restaurant(
        name: 'La Trattoria',
        cuisine: 'Italienne',
        rating: 4.7,
        stars: 3,
        imageUrl: 'assets/images/image.png',
      ),
      Restaurant(
        name: 'L\'Étoile Dorée',
        cuisine: 'Gastronomique',
        rating: 4.9,
        stars: 5,
        imageUrl: 'assets/images/image.png',
      ),
      Restaurant(
        name: 'Le Petit Bistro',
        cuisine: 'Française',
        rating: 4.3,
        stars: 2,
        imageUrl: 'assets/images/image.png',
      ),
      Restaurant(
        name: 'Saveurs d\'Orient',
        cuisine: 'Libanaise',
        rating: 4.6,
        stars: 3,
        imageUrl: 'assets/images/image.png',
      ),
      Restaurant(
        name: 'El Taqueria',
        cuisine: 'Mexicaine',
        rating: 4.4,
        stars: 2,
        imageUrl: 'assets/images/image.png',
      ),
      Restaurant(
        name: 'Délices de la Mer',
        cuisine: 'Fruits de mer',
        rating: 4.8,
        stars: 4,
        imageUrl: 'assets/images/image.png',
      ),
      Restaurant(
        name: 'Le Palais Royal',
        cuisine: 'Haute cuisine',
        rating: 5.0,
        stars: 5,
        imageUrl: 'assets/images/image.png',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('IUTables\'O'),
        backgroundColor: Color(0xFFFA8C3B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Texte d'introduction
            Text(
              'Bienvenue sur IUTables\'O!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Text(
              'Voici une sélection de restaurants populaires :',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            // Liste des restaurants
            Expanded(
              child: ListView.builder(
                itemCount: popularRestaurants.length,
                itemBuilder: (context, index) {
                  return restaurantCard(context, popularRestaurants[index]);
                },
              ),
            ),
            SizedBox(height: 16),
            // Liens vers les pages principales (en bas)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                featureCard(context, 'Mes Restaurants', Icons.restaurant, () {}),
                featureCard(context, 'Mes Critiques', Icons.rate_review, () {}),
                featureCard(context, 'Paramètres', Icons.settings, () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour une carte de restaurant avec image, nom, cuisine et note
  Widget restaurantCard(BuildContext context, Restaurant restaurant) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200, // Ajout d'une hauteur fixe
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Image.asset(
                  restaurant.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(10, 30, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        restaurant.cuisine,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < restaurant.stars ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${restaurant.rating}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour une carte de fonctionnalité
  Widget featureCard(BuildContext context, String title, IconData icon, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: Color(0xFFF8EDE3), // Couleur beige très douce
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 30, color: Color(0xFFFA8C3B)), // Icône avec couleur orange
              SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
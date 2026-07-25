import 'package:flutter/material.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedGame = 'Pokémon';
  String _selectedCondition = 'NM (Near Mint)';

  static const _conditions = [
    'NM (Near Mint)',
    'LP (Lightly Played)',
    'MP (Moderately Played)',
    'HP (Heavily Played)',
    'D (Damaged)',
  ];

  @override
  void dispose() {
    _cardNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle annonce')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upload photo à venir')),
                  );
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      const Text('Ajouter une photo'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _cardNameController,
                decoration: const InputDecoration(labelText: 'Nom de la carte'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Requis',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGame,
                decoration: const InputDecoration(labelText: 'Jeu'),
                items: const [
                  DropdownMenuItem(value: 'Pokémon', child: Text('Pokémon')),
                  DropdownMenuItem(value: 'Magic', child: Text('Magic')),
                  DropdownMenuItem(value: 'Yu-Gi-Oh!', child: Text('Yu-Gi-Oh!')),
                ],
                onChanged: (v) => setState(() => _selectedGame = v ?? _selectedGame),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Édition'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCondition,
                decoration: const InputDecoration(labelText: 'État'),
                items: _conditions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCondition = v ?? _selectedCondition),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Prix',
                  suffixText: '€',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  final price = double.tryParse(v);
                  return price != null && price > 0 ? null : 'Prix invalide';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Création d\'annonce à venir')),
                    );
                  }
                },
                child: const Text('Publier l\'annonce'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:curiosity/theme/colors.dart';
import 'package:flutter/material.dart';

class SourcesSection extends StatefulWidget {
  const SourcesSection({super.key});

  @override
  State<SourcesSection> createState() => _SourcesSectionState();
}

class _SourcesSectionState extends State<SourcesSection> {
  List<Map<String, dynamic>> searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.source_outlined,
            color: Colors.white70, 
            ),
            SizedBox(width: 8),
            Text("Sources", style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: searchResults.map((res){
            return Container(
              width: 150,
              padding: EdgeInsets.all(16),
              decoration:BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(8),
              ) ,
              child: Column(
                children: [
                  Text(res['url'], 
                    style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                      ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}
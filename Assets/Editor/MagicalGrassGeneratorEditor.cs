using UnityEditor;
using UnityEngine;

/// <summary>
/// Udostepnia dodatkowe przyciski do generowania i usuwania trawy.
/// </summary>
[CustomEditor(typeof(MagicalGrassGenerator))]
public sealed class MagicalGrassGeneratorEditor : Editor
{
    // Tworzy wlasny wyglad edytora dla komponentu MagicalGrassGenerator.
    public override void OnInspectorGUI()
    {
        // Wyswietla standardowe pola komponentu w Inspectorze.
        DrawDefaultInspector();

        // Pobiera obiekt MagicalGrassGenerator, ktory jest aktualnie edytowany.
        MagicalGrassGenerator generator = (MagicalGrassGenerator)target;

        // Dodaje odstep miedzy standardowymi ustawieniami a przyciskami.
        GUILayout.Space(10f);

        // Tworzy przycisk generowania trawy o wysokosci 34 pikseli.
        // Po kliknieciu wywoluje metode GenerateGrass() na generatorze.
        if (GUILayout.Button("Generate Magical Grass", GUILayout.Height(34f)))
            generator.GenerateGrass();

        // Tworzy przycisk usuwania wygenerowanej trawy o wysokosci 30 pikseli.
        // Po kliknieciu wywoluje metode ClearGrass() na generatorze.
        if (GUILayout.Button("Clear Generated Grass", GUILayout.Height(30f)))
            generator.ClearGrass();
    }
}
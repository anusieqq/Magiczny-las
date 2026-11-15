using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

/// <summary>
/// Generuje proceduralna geometrie trawy dopasowana do powierzchni terenu.
/// Dzieli obszar na mniejsze chunki, aby uporzadkowac wygenerowana geometrie.
/// </summary>
public class MagicalGrassGenerator : MonoBehaviour
{
    [Header("Teren")]
    public Terrain terrain;

    [Header("Gestosc trawy")]
    [Min(0.1f)] public float density = 1.5f;
    [Min(1f)] public float chunkSize = 10f;

    [Header("Ksztalt pojedynczego zdzbla")]
    [Min(0.1f)] public float minHeight = 0.35f;
    [Min(0.1f)] public float maxHeight = 0.8f;
    [Min(0.01f)] public float bladeWidth = 0.09f;
    [Range(0f, 1f)] public float curvature = 0.3f;

    [Header("Zroznicowanie zdzbel")]
    [Range(0f, 1f)] public float heightRandomness = 0.4f;
    [Range(0f, 1f)] public float widthRandomness = 0.3f;
    public int seed = 12345;

    [Header("Material")]
    public Material grassMaterial;

    // Lista obiektow zawierajacych wygenerowane fragmenty geometrii trawy.
    private readonly List<GameObject> chunks = new();

    [ContextMenu("Generate Magical Grass")]
    public void GenerateGrass()
    {
        // Sprawdzenie poprawnosci przypisania terenu przed rozpoczeciem generowania.
        if (terrain == null || terrain.terrainData == null)
        {
            Debug.LogError("MagicalGrassGenerator: przypisz teren przed wygenerowaniem trawy.", this);
            return;
        }

        // Sprawdzenie, czy przypisano material wykorzystywany do renderowania trawy.
        if (grassMaterial == null)
        {
            Debug.LogError("MagicalGrassGenerator: przypisz material trawy przed rozpoczeciem generowania.", this);
            return;
        }

        // Ograniczenie parametrow do minimalnych wartosci zapobiegajacych nieprawidlowym obliczeniom.
        density = Mathf.Max(0.1f, density);
        chunkSize = Mathf.Max(1f, chunkSize);
        bladeWidth = Mathf.Max(0.01f, bladeWidth);

        // Usuniecie poprzednio wygenerowanej geometrii przed utworzeniem nowej.
        ClearGrass();

        TerrainData data = terrain.terrainData;
        Vector3 size = data.size;

        // Inicjalizacja generatora liczb pseudolosowych zapewniajaca powtarzalnosc wynikow.
        System.Random random = new System.Random(seed);

        // Obliczenie liczby chunkow potrzebnych do pokrycia calej powierzchni terenu.
        int countX = Mathf.CeilToInt(size.x / chunkSize);
        int countZ = Mathf.CeilToInt(size.z / chunkSize);

        // Generowanie kolejnych fragmentow terenu w dwoch wymiarach.
        for (int x = 0; x < countX; x++)
        {
            for (int z = 0; z < countZ; z++)
            {
                GenerateChunk(x, z, random);
            }
        }

        Debug.Log("MagicalGrassGenerator: generowanie siatek trawy zakonczone.", this);
    }

    private void GenerateChunk(int chunkX, int chunkZ, System.Random random)
    {
        TerrainData data = terrain.terrainData;
        Vector3 size = data.size;

        // Wyznaczenie poczatkowych wspolrzednych chunka w przestrzeni terenu.
        float startX = chunkX * chunkSize;
        float startZ = chunkZ * chunkSize;

        // Ograniczenie granic chunka do rzeczywistych wymiarow terenu.
        float endX = Mathf.Min(startX + chunkSize, size.x);
        float endZ = Mathf.Min(startZ + chunkSize, size.z);

        // Obliczenie powierzchni chunka i liczby zdzbel na podstawie ustawionej gestosci.
        float area = (endX - startX) * (endZ - startZ);
        int bladeCount = Mathf.RoundToInt(area * density);

        // Listy przechowujace dane geometryczne i wizualne generowanej siatki.
        List<Vector3> vertices = new();
        List<Vector2> uvs = new();
        List<Color> colors = new();
        List<int> triangles = new();

        for (int i = 0; i < bladeCount; i++)
        {
            // Losowanie polozenia zdzbla w granicach aktualnego chunka.
            float x = Mathf.Lerp(startX, endX, (float)random.NextDouble());
            float z = Mathf.Lerp(startZ, endZ, (float)random.NextDouble());

            // Normalizacja wspolrzednych do zakresu wymaganego przez TerrainData.
            float u = x / size.x;
            float v = z / size.z;

            // Pobranie wysokosci powierzchni oraz jej lokalnej normalnej.
            float y = data.GetInterpolatedHeight(u, v);
            Vector3 normal = data.GetInterpolatedNormal(u, v);

            // Przeksztalcenie polozenia punktu z przestrzeni lokalnej terenu na przestrzen swiata.
            Vector3 worldPosition = terrain.transform.TransformPoint(
                new Vector3(x, y, z));

            // Przeksztalcenie normalnej do przestrzeni swiata z zachowaniem jej jednostkowej dlugosci.
            Vector3 worldNormal = terrain.transform
                .TransformDirection(normal).normalized;

            // Losowanie wysokosci zdzbla w zakresie okreslonym przez parametry minimalne i maksymalne.
            float randomHeight = Mathf.Lerp(
                Mathf.Min(minHeight, maxHeight),
                Mathf.Max(minHeight, maxHeight),
                (float)random.NextDouble());

            // Wprowadzenie dodatkowego zroznicowania wysokosci wzgledem wartosci bazowej.
            randomHeight *= Mathf.Lerp(
                1f - heightRandomness, 1f + heightRandomness,
                (float)random.NextDouble());

            // Losowe dostosowanie szerokosci zdzbla.
            float width = bladeWidth * Mathf.Lerp(
                1f - widthRandomness, 1f + widthRandomness,
                (float)random.NextDouble());

            // Wylosowanie kierunku poczatkowego zdzbla wokol osi normalnej powierzchni.
            float angle = (float)random.NextDouble() * 360f;

            Vector3 direction = Quaternion.AngleAxis(angle, worldNormal)
                * Vector3.forward;

            // Usuniecie skladowej prostopadlej do powierzchni, aby kierunek lezal w jej plaszczyznie.
            direction = Vector3.ProjectOnPlane(
                direction, worldNormal).normalized;

            // Utworzenie pierwszej plaszczyzny zdzbla na podstawie wylosowanych parametrow.
            AddBladePlane(
                vertices, uvs, colors, triangles,
                worldPosition, worldNormal, direction,
                randomHeight, width, random);

            // Wyznaczenie drugiego kierunku prostopadlego do pierwszej plaszczyzny.
            Vector3 secondDirection = Vector3.Cross(
                worldNormal, direction).normalized;

            // Utworzenie drugiej plaszczyzny dla uzyskania pelniejszego wygladu zdzbla.
            AddBladePlane(
                vertices, uvs, colors, triangles,
                worldPosition, worldNormal, secondDirection,
                randomHeight, width, random);
        }

        // Pominiecie tworzenia siatki, jesli nie wygenerowano zadnych wierzcholkow.
        if (vertices.Count == 0)
            return;

        // Utworzenie nowej siatki reprezentujacej geometrie trawy w aktualnym chunku.
        Mesh mesh = new Mesh();
        mesh.name = $"MagicalGrass_{chunkX}_{chunkZ}";

        // Zastosowanie 32-bitowego indeksowania, gdy liczba wierzcholkow przekracza limit 16-bitowy.
        if (vertices.Count > 65535)
            mesh.indexFormat = IndexFormat.UInt32;

        // Przekazanie danych wierzcholkow, UV, kolorow i trojkatow do siatki.
        mesh.SetVertices(vertices);
        mesh.SetUVs(0, uvs);
        mesh.SetColors(colors);
        mesh.SetTriangles(triangles, 0);

        // Przeliczenie normalnych i granic siatki na podstawie wygenerowanej geometrii.
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();

        // Utworzenie obiektu sceny przechowujacego wygenerowana siatke.
        GameObject chunk = new GameObject(mesh.name);
        chunk.transform.SetParent(transform, false);

        // Dodanie komponentow odpowiedzialnych za geometrie i jej renderowanie.
        MeshFilter filter = chunk.AddComponent<MeshFilter>();
        MeshRenderer renderer = chunk.AddComponent<MeshRenderer>();

        // Przypisanie siatki oraz materialu trawy.
        filter.sharedMesh = mesh;
        renderer.sharedMaterial = grassMaterial;

        // Zapisanie referencji do wygenerowanego chunka.
        chunks.Add(chunk);
    }

    void AddBladePlane(
        List<Vector3> vertices,
        List<Vector2> uvs,
        List<Color> colors,
        List<int> triangles,
        Vector3 position,
        Vector3 normal,
        Vector3 direction,
        float height,
        float width,
        System.Random random)
    {
        // Liczba segmentow okreslajacych szczegolowosc geometrii pojedynczego zdzbla.
        const int segments = 3;

        // Wyznaczenie osi szerokosci zdzbla prostopadlej do jego kierunku i normalnej powierzchni.
        Vector3 right = Vector3.Cross(normal, direction).normalized;

        // Losowy mnoznik intensywnosci wygiecia zdzbla.
        float randomBend = (float)random.NextDouble() * 0.5f + 0.75f;

        // Wyznaczenie kierunku i sily wygiecia na podstawie ustawionej krzywizny.
        Vector3 bendDirection = direction * curvature * randomBend;

        // Zapamietanie indeksu pierwszego wierzcholka nowej plaszczyzny.
        int startIndex = vertices.Count;

        for (int i = 0; i <= segments; i++)
        {
            // Normalizacja polozenia segmentu wzdluz wysokosci zdzbla.
            float t = (float)i / segments;

            // Stopniowe zwezanie zdzbla w kierunku jego wierzcholka.
            float currentWidth = width * (1f - t * 0.9f);

            // Obliczenie polozenia srodka segmentu z uwzglednieniem wysokosci i wygiecia.
            Vector3 center = position
                + normal * (height * t)
                + bendDirection * (height * t * t);

            // Wyznaczenie lewego i prawego wierzcholka segmentu.
            Vector3 left = center - right * currentWidth * 0.5f;
            Vector3 rightPoint = center + right * currentWidth * 0.5f;

            // Przeksztalcenie pozycji wierzcholkow ze wspolrzednych swiata na lokalne wspolrzedne generatora.
            vertices.Add(transform.InverseTransformPoint(left));
            vertices.Add(transform.InverseTransformPoint(rightPoint));

            // Przypisanie wspolrzednych UV wzdluz wysokosci zdzbla.
            uvs.Add(new Vector2(0f, t));
            uvs.Add(new Vector2(1f, t));

            // Losowanie wartosci koloru w celu uzyskania naturalnego zroznicowania wygladu trawy.
            Color variation = new Color(
                random.Next(80, 121) / 100f,
                random.Next(80, 121) / 100f,
                random.Next(80, 121) / 100f,
                1f);

            colors.Add(variation);
            colors.Add(variation);
        }

        // Polaczenie kolejnych segmentow w trojkaty tworzace geometrie plaszczyzny.
        for (int i = 0; i < segments; i++)
        {
            int a = startIndex + i * 2;
            int b = a + 1;
            int c = a + 2;
            int d = a + 3;

            // Pierwszy trojkat laczacy dwa sasiednie segmenty.
            triangles.Add(a);
            triangles.Add(c);
            triangles.Add(b);

            // Drugi trojkat uzupelniajacy prostokatny fragment siatki.
            triangles.Add(b);
            triangles.Add(c);
            triangles.Add(d);
        }
    }

    [ContextMenu("Clear Magical Grass")]
    public void ClearGrass()
    {
        // Usuwanie wylacznie obiektow utworzonych przez generator,
        // bez naruszania pozostalych elementow hierarchii sceny.
        for (int i = transform.childCount - 1; i >= 0; i--)
        {
            Transform child = transform.GetChild(i);

            // Rozpoznawanie wygenerowanych chunkow na podstawie ich prefiksu nazwy.
            if (!child.name.StartsWith("MagicalGrass_", System.StringComparison.Ordinal))
                continue;

            // Pobranie siatki przypisanej do usuwanego obiektu.
            MeshFilter filter = child.GetComponent<MeshFilter>();

            if (filter != null && filter.sharedMesh != null)
            {
                Mesh mesh = filter.sharedMesh;

                // Odlaczenie siatki od komponentu przed zwolnieniem zasobu.
                filter.sharedMesh = null;

                // Dobranie metody usuwania zasobu do aktualnego trybu pracy Unity.
                if (Application.isPlaying)
                    Destroy(mesh);
                else
                    DestroyImmediate(mesh);
            }

            // Usuniecie obiektu chunka z hierarchii sceny.
            if (Application.isPlaying)
                Destroy(child.gameObject);
            else
                DestroyImmediate(child.gameObject);
        }

        // Wyczyszczenie listy referencji do wygenerowanych obiektow.
        chunks.Clear();

        Debug.Log("MagicalGrassGenerator: wygenerowane siatki trawy zostaly usuniete.", this);
    }
}
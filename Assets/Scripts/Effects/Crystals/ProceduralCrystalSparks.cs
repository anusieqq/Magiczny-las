using UnityEngine;

/// <summary>
/// Generuje i animuje proceduralne czasteczki swietlne wokol krysztalu.
/// Czworokaty reprezentujace czasteczki sa zawsze skierowane w strone kamery.
/// </summary>
[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class ProceduralCrystalSparks : MonoBehaviour
{
    [Header("Referencje")]
    [SerializeField] private Transform crystal;
    [SerializeField] private Material sparkMaterial;

    [Header("Parametry czasteczek")]
    [SerializeField, Range(5, 100)] private int sparkCount = 71;
    [SerializeField, Min(0.1f)] private float orbitRadius = 1.55f;
    [SerializeField, Min(0.01f)] private float sparkSize = 0.06f;
    [SerializeField, Min(0.1f)] private float lifetime = 3f;

    [Header("Ruch czasteczek")]
    [SerializeField] private float orbitSpeed = 0.7f;
    [SerializeField] private float riseSpeed = 0.3f;
    [SerializeField] private float wobbleAmount = 0.88f;
    [SerializeField] private float wobbleSpeed = 0.5f;

    // Siatka przechowujaca geometrie wszystkich czasteczek.
    private Mesh sparkMesh;

    // Komponenty odpowiedzialne za przechowywanie i wyswietlanie siatki.
    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;

    // Referencja do aktywnej kamery wykorzystywanej do orientacji czasteczek.
    private Camera cachedCamera;

    // Tablice przechowujace dane geometryczne i wizualne siatki.
    private Vector3[] vertices;
    private Vector2[] uvs;
    private int[] triangles;
    private Color[] colors;

    // Tablica przechowujaca parametry animacji poszczegolnych czasteczek.
    private Spark[] sparks;

    private class Spark
    {
        // Aktualny kat polozenia czasteczki na orbicie.
        public float angle;

        // Aktualna wysokosc czasteczki wzgledem srodka animacji.
        public float height;

        // Czas, jaki uplynal od utworzenia czasteczki.
        public float age;

        // Calkowity czas zycia czasteczki.
        public float lifetime;

        // Indywidualny promien orbity czasteczki.
        public float radius;

        // Rozmiar czasteczki.
        public float size;

        // Przesuniecie fazowe wykorzystywane do zroznicowania ruchu.
        public float phase;

        // Indywidualny mnoznik predkosci ruchu.
        public float speed;
    }

    private void Awake()
    {
        // Pobranie glownej kamery sceny w celu wykorzystania jej orientacji.
        cachedCamera = Camera.main;
    }

    private void Start()
    {
        // Ustalenie obiektu, wzgledem ktorego bedzie generowany efekt.
        // W przypadku braku przypisanej referencji wykorzystywany jest obiekt nadrzedny.
        if (crystal == null)
            crystal = transform.parent != null ? transform.parent : transform;

        // Pobranie komponentow odpowiedzialnych za obsluge siatki.
        meshFilter = GetComponent<MeshFilter>();
        meshRenderer = GetComponent<MeshRenderer>();

        // Przypisanie materialu wykorzystywanego do wyswietlania czasteczek.
        if (sparkMaterial != null)
            meshRenderer.sharedMaterial = sparkMaterial;
        else
            Debug.LogError(
                "ProceduralCrystalSparks: przypisz material do pola Spark Material.",
                this
            );

        // Inicjalizacja geometrii i parametrow wszystkich czasteczek.
        CreateSparks();
    }

    private void CreateSparks()
    {
        int count = sparkCount;

        // Przygotowanie tablic danych dla wszystkich czworokatow siatki.
        // Kazda czasteczka sklada sie z czterech wierzcholkow i dwoch trojkatow.
        vertices = new Vector3[count * 4];
        uvs = new Vector2[count * 4];
        colors = new Color[count * 4];
        triangles = new int[count * 6];
        sparks = new Spark[count];

        for (int i = 0; i < count; i++)
        {
            int v = i * 4;
            int t = i * 6;

            // Inicjalizacja czterech wierzcholkow tworzacych pojedynczy czworokat.
            vertices[v] = Vector3.zero;
            vertices[v + 1] = Vector3.zero;
            vertices[v + 2] = Vector3.zero;
            vertices[v + 3] = Vector3.zero;

            // Przypisanie wspolrzednych UV okreslajacych sposob nakladania tekstury.
            uvs[v] = new Vector2(0, 0);
            uvs[v + 1] = new Vector2(1, 0);
            uvs[v + 2] = new Vector2(1, 1);
            uvs[v + 3] = new Vector2(0, 1);

            // Zdefiniowanie dwoch trojkatow skladajacych sie na czworokat.
            triangles[t] = v;
            triangles[t + 1] = v + 2;
            triangles[t + 2] = v + 1;
            triangles[t + 3] = v;
            triangles[t + 4] = v + 3;
            triangles[t + 5] = v + 2;

            // Utworzenie obiektu czasteczki i inicjalizacja jego parametrow.
            sparks[i] = new Spark();
            ResetSpark(sparks[i], true);
        }

        // Utworzenie dynamicznej siatki przeznaczonej do czestej aktualizacji.
        sparkMesh = new Mesh();
        sparkMesh.name = "Procedural Crystal Sparks";
        sparkMesh.MarkDynamic();

        // Przekazanie przygotowanych danych geometrycznych i kolorystycznych do siatki.
        sparkMesh.vertices = vertices;
        sparkMesh.uv = uvs;
        sparkMesh.triangles = triangles;
        sparkMesh.colors = colors;

        // Przypisanie wygenerowanej siatki do komponentu MeshFilter.
        meshFilter.sharedMesh = sparkMesh;
    }

    private void ResetSpark(Spark spark, bool randomHeight)
    {
        // Losowanie poczatkowego polozenia katowego na orbicie.
        spark.angle = Random.Range(0f, Mathf.PI * 2f);

        // Losowanie indywidualnego promienia orbity.
        spark.radius = Random.Range(orbitRadius * 0.45f, orbitRadius);

        // Rozpoczecie animacji od losowego momentu lub od poczatku cyklu.
        spark.age = randomHeight ? Random.Range(0f, lifetime) : 0f;

        // Zroznicowanie czasu zycia poszczegolnych czasteczek.
        spark.lifetime = lifetime * Random.Range(0.7f, 1.3f);

        // Losowe zroznicowanie rozmiaru czasteczek.
        spark.size = sparkSize * Random.Range(0.5f, 1.4f);

        // Przypisanie indywidualnej fazy ruchu oscylacyjnego.
        spark.phase = Random.Range(0f, Mathf.PI * 2f);

        // Losowanie mnoznika predkosci dla uzyskania naturalniejszego ruchu.
        spark.speed = Random.Range(0.7f, 1.3f);

        // Ustalenie poczatkowej wysokosci czasteczki.
        spark.height = randomHeight
            ? Random.Range(-orbitRadius * 0.5f, orbitRadius * 0.5f)
            : -orbitRadius * 0.5f;
    }

    private void LateUpdate()
    {
        // Pomini?cie aktualizacji, jesli siatka lub obiekt odniesienia nie istnieje.
        if (sparkMesh == null || crystal == null)
            return;

        // Ponowne pobranie kamery, jesli nie byla dostepna podczas inicjalizacji.
        if (cachedCamera == null)
            cachedCamera = Camera.main;

        // Pobranie czasu od ostatniej klatki do aktualizacji animacji.
        float dt = Time.deltaTime;

        for (int i = 0; i < sparks.Length; i++)
        {
            Spark spark = sparks[i];

            // Aktualizacja wieku czasteczki.
            spark.age += dt;

            // Ponowna inicjalizacja czasteczki po zakonczeniu jej czasu zycia.
            if (spark.age >= spark.lifetime)
                ResetSpark(spark, false);

            // Aktualizacja polozenia katowego i wysokosci czasteczki.
            spark.angle += orbitSpeed * spark.speed * dt;
            spark.height += riseSpeed * dt;

            // Powrot czasteczki na dolny poziom po przekroczeniu gornego zakresu ruchu.
            if (spark.height > orbitRadius * 0.5f)
                spark.height = -orbitRadius * 0.5f;

            // Obliczenie dodatkowego wychylenia w osi X za pomoca funkcji sinus.
            float wobbleX = Mathf.Sin(
                Time.time * wobbleSpeed + spark.phase
            ) * wobbleAmount;

            // Obliczenie dodatkowego wychylenia w osi Z za pomoca funkcji cosinus.
            float wobbleZ = Mathf.Cos(
                Time.time * wobbleSpeed * 0.8f + spark.phase
            ) * wobbleAmount;

            // Wyznaczenie lokalnego polozenia czasteczki na orbicie
            // z uwzglednieniem ruchu obrotowego i dodatkowych wychylen.
            Vector3 localPosition = new Vector3(
                Mathf.Cos(spark.angle) * spark.radius + wobbleX,
                spark.height,
                Mathf.Sin(spark.angle) * spark.radius + wobbleZ
            );

            // Przeksztalcenie lokalnego polozenia na wspolrzedne swiatowe.
            Vector3 worldPosition = crystal.TransformPoint(localPosition);

            // Pobranie kierunkow osi kamery w celu utrzymania czasteczek
            // w orientacji skierowanej bezposrednio w jej strone.
            Vector3 right = cachedCamera != null
                ? cachedCamera.transform.right
                : Vector3.right;
            Vector3 up = cachedCamera != null
                ? cachedCamera.transform.up
                : Vector3.up;

            float size = spark.size;

            int v = i * 4;

            // Wyznaczenie polozenia czterech wierzcholkow czworokata
            // na podstawie orientacji kamery i rozmiaru czasteczki.
            // Przeksztalcenie wspolrzednych swiatowych na lokalne wspolrzedne siatki.
            vertices[v] = transform.InverseTransformPoint(
                worldPosition + (-right - up) * size
            );
            vertices[v + 1] = transform.InverseTransformPoint(
                worldPosition + (right - up) * size
            );
            vertices[v + 2] = transform.InverseTransformPoint(
                worldPosition + (right + up) * size
            );
            vertices[v + 3] = transform.InverseTransformPoint(
                worldPosition + (-right + up) * size
            );

            // Normalizacja wieku czasteczki do zakresu od 0 do 1.
            float normalizedAge = spark.age / spark.lifetime;

            // Wyznaczenie narastania i zanikania przezroczystosci czasteczki.
            float fadeIn = Mathf.Clamp01(normalizedAge * 5f);
            float fadeOut = Mathf.Clamp01((1f - normalizedAge) * 4f);

            // Obliczenie pulsacji jasnosci czasteczki.
            float pulse = 0.75f + 0.25f * Mathf.Sin(
                Time.time * 5f + spark.phase
            );

            // Polaczenie efektu pojawiania sie, zanikania i pulsowania.
            float alpha = fadeIn * fadeOut * pulse;
            Color sparkColor = new Color(1f, 1f, 1f, alpha);

            // Przypisanie jednakowej wartosci koloru i przezroczystosci
            // wszystkim wierzcholkom pojedynczej czasteczki.
            colors[v] = sparkColor;
            colors[v + 1] = sparkColor;
            colors[v + 2] = sparkColor;
            colors[v + 3] = sparkColor;
        }

        // Przekazanie zaktualizowanych pozycji i kolorow do siatki.
        sparkMesh.vertices = vertices;
        sparkMesh.colors = colors;

        // Ponowne obliczenie granic siatki po zmianie polozenia wierzcholkow.
        sparkMesh.RecalculateBounds();
    }

    private void OnDestroy()
    {
        // Zwolnienie zasobow siatki utworzonej dynamicznie przez skrypt.
        if (sparkMesh != null)
            Destroy(sparkMesh);
    }
}
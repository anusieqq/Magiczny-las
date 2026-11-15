using UnityEngine;

/// <summary>
/// Odpowiada za animowane generowanie pnaczy spiralnie oplatajacych drzewo
/// oraz za ruch swietlikow kra?acych wokol jego pnia.
/// </summary>
public class MagicTreeVines : MonoBehaviour
{
    [Header("Materials")]
    [SerializeField] private Material vineMaterial;
    [SerializeField] private Material fireflyMaterial;

    [Header("Activation")]
    [SerializeField] private Transform player;
    [SerializeField] private float activationDistance = 5f;
    [SerializeField] private bool alwaysActive = true;

    [Header("Vines")]
    [SerializeField] private int vineCount = 5;
    [SerializeField] private int pointsPerVine = 100;
    [SerializeField] private float vineHeight = 4.5f;
    [SerializeField] private float trunkRadius = 0.65f;
    [SerializeField] private float vineWidth = 0.045f;
    [SerializeField] private float spiralTurns = 1.5f;
    [SerializeField] private float irregularity = 0.18f;
    [SerializeField] private float sway = 0.06f;

    [Header("Growth and Retraction")]
    [SerializeField] private float growthDuration = 3f;
    [SerializeField] private float delayBetweenVines = 0.45f;

    [Header("Fireflies")]
    [SerializeField] private int fireflyCount = 24;
    [SerializeField] private float fireflyRadius = 1.5f;
    [SerializeField] private float fireflyHeight = 4.5f;
    [SerializeField] private float fireflySize = 0.055f;
    [SerializeField] private float fireflySpeed = 0.7f;
    [SerializeField] private float fireflyWobble = 0.18f;

    // Tablice przechowujace renderery pnaczy, ich sciezki oraz aktualny postep animacji.
    private LineRenderer[] vines;
    private Vector3[][] paths;
    private float[] vineProgress;
    private float[] vineDelays;

    // Dane potrzebne do sterowania polozeniem, ruchem i animacja swietlikow.
    private Transform fireflyRoot;
    private Transform[] fireflies;
    private float[] fireflyOffsets;
    private float[] fireflyPhases;

    private float activationTimer;
    private bool wasActive;

    private void Start()
    {
        // Material pnaczy jest wymagany do poprawnego wyswietlenia efektu.
        if (vineMaterial == null)
        {
            Debug.LogError(
                "MagicTreeVines: assign a material to Vine Material.",
                this
            );

            enabled = false;
            return;
        }

        // Ograniczenie parametrow do wartosci zapewniajacych poprawne dzialanie.
        vineCount = Mathf.Max(1, vineCount);
        pointsPerVine = Mathf.Max(10, pointsPerVine);
        fireflyCount = Mathf.Max(0, fireflyCount);
        growthDuration = Mathf.Max(0.1f, growthDuration);

        CreateVines();
        CreateFireflies();
    }

    private void CreateVines()
    {
        // Przygotowanie tablic przechowujacych dane wszystkich pnaczy.
        vines = new LineRenderer[vineCount];
        paths = new Vector3[vineCount][];
        vineProgress = new float[vineCount];
        vineDelays = new float[vineCount];

        for (int i = 0; i < vineCount; i++)
        {
            // Kazde pnacze jest osobnym obiektem z komponentem LineRenderer.
            GameObject obj = new GameObject(
                "Magic Vine " + i
            );

            obj.transform.SetParent(transform, false);

            LineRenderer line =
                obj.AddComponent<LineRenderer>();

            // Punkty pnacza sa przechowywane w lokalnym ukladzie wspolrzednych drzewa.
            line.useWorldSpace = false;
            line.sharedMaterial = vineMaterial;

            // Pnacze zweza sie ku koncowi, co nadaje mu bardziej naturalny wyglad.
            line.startWidth = vineWidth;
            line.endWidth = vineWidth * 0.25f;

            // Wyg?adzenie zakonczen i naroznikow linii.
            line.numCapVertices = 4;
            line.numCornerVertices = 4;
            line.positionCount = 0;

            // Wylaczenie cieni ogranicza dodatkowe obliczenia renderowania.
            line.shadowCastingMode =
                UnityEngine.Rendering.ShadowCastingMode.Off;

            line.receiveShadows = false;

            vines[i] = line;

            // Wyznaczenie pelnej trasy pnacza oraz opoznienia jego wzrostu.
            paths[i] = GenerateVinePath(i);
            vineDelays[i] = i * delayBetweenVines;
        }
    }

    private Vector3[] GenerateVinePath(int index)
    {
        Vector3[] points = new Vector3[pointsPerVine];

        // Rozmieszczenie poczatkow pnaczy wokol pnia z niewielkim losowym przesunieciem.
        float startAngle =
            index / (float)vineCount * Mathf.PI * 2f
            + Random.Range(-0.35f, 0.35f);

        // Losowe zroznicowanie liczby obrotow spirali dla kazdego pnacza.
        float turns =
            spiralTurns * Random.Range(0.7f, 1.3f);

        // Fazy sinusoid zapewniaja niezalezne, nieregularne odchylenia trasy.
        float phase1 = Random.Range(0f, 10f);
        float phase2 = Random.Range(0f, 10f);

        for (int i = 0; i < pointsPerVine; i++)
        {
            // Parametr t okresla polozenie punktu wzdluz pnacza w zakresie 0-1.
            float t = i / (float)(pointsPerVine - 1);

            // Kat okresla polozenie punktu na spirali oplatajacej pien.
            float angle =
                startAngle + t * turns * Mathf.PI * 2f;

            // Dwie sinusoidy wprowadzaja nieregularnosci do promienia spirali.
            float variation =
                Mathf.Sin(t * 17f + phase1) * irregularity
                + Mathf.Sin(t * 31f + phase2)
                * irregularity * 0.4f;

            float r = trunkRadius + variation;

            // Przeliczenie wspolrzednych biegunowych na polozenie w plaszczyznie XZ.
            float x = Mathf.Cos(angle) * r;
            float z = Mathf.Sin(angle) * r;

            // Dodatkowe odchylenia zapobiegaja uzyskaniu idealnie regularnej spirali.
            x += Mathf.Sin(t * 12f + phase2) * sway;
            z += Mathf.Cos(t * 15f + phase1) * sway;

            // Wysokosc pnacza rosnie wzdluz jego trasy z niewielkim falowaniem.
            float y =
                vineHeight * t
                + Mathf.Sin(t * Mathf.PI * 2f + phase1) * 0.08f;

            points[i] = new Vector3(x, y, z);
        }

        return points;
    }

    private void CreateFireflies()
    {
        // Utworzenie obiektu nadrzednego grupujacego wszystkie swietliki.
        fireflyRoot = new GameObject(
            "Magic Fireflies"
        ).transform;

        fireflyRoot.SetParent(transform, false);
        fireflyRoot.localPosition = Vector3.zero;

        // Przygotowanie tablic przechowujacych obiekty i ich indywidualne parametry animacji.
        fireflies = new Transform[fireflyCount];
        fireflyOffsets = new float[fireflyCount];
        fireflyPhases = new float[fireflyCount];

        for (int i = 0; i < fireflyCount; i++)
        {
            // Swietlik jest reprezentowany przez prosta geometrie sfery.
            GameObject obj = GameObject.CreatePrimitive(
                PrimitiveType.Sphere
            );

            obj.name = "Firefly " + i;
            obj.transform.SetParent(fireflyRoot, false);

            // Usuniecie collidera, poniewaz swietliki nie uczestnicza w fizyce.
            Collider col = obj.GetComponent<Collider>();

            if (col != null)
                Destroy(col);

            Renderer rend = obj.GetComponent<Renderer>();

            // Swietliki korzystaja z osobnego materialu lub materialu pnaczy jako zamiennika.
            rend.sharedMaterial =
                fireflyMaterial != null
                ? fireflyMaterial
                : vineMaterial;

            // Swietliki nie rzucaja ani nie odbieraja cieni.
            rend.shadowCastingMode =
                UnityEngine.Rendering.ShadowCastingMode.Off;

            rend.receiveShadows = false;

            fireflies[i] = obj.transform;

            // Losowe przesuniecia i fazy zapewniaja zroznicowany ruch swietlikow.
            fireflyOffsets[i] =
                Random.Range(0f, Mathf.PI * 2f);

            fireflyPhases[i] =
                Random.Range(0f, Mathf.PI * 2f);

            // Poczatkowo swietliki sa niewidoczne.
            obj.transform.localScale = Vector3.zero;
        }
    }

    private void Update()
    {
        // Efekt moze byc aktywny caly czas lub tylko w poblizu gracza.
        bool shouldBeActive = alwaysActive;

        if (player != null)
        {
            float distance = Vector3.Distance(
                player.position,
                transform.position
            );

            if (distance <= activationDistance)
                shouldBeActive = true;
        }

        // Ponowne wejscie gracza w zasieg rozpoczyna sekwencje wzrostu od poczatku.
        if (shouldBeActive && !wasActive)
        {
            activationTimer = 0f;
        }

        wasActive = shouldBeActive;

        // Aktualizacja wzrostu pnaczy i animacji swietlikow.
        UpdateVineGrowth(shouldBeActive);
        UpdateFireflies();
    }

    private void UpdateVineGrowth(bool shouldGrow)
    {
        float dt = Time.deltaTime;

        for (int i = 0; i < vines.Length; i++)
        {
            if (shouldGrow)
            {
                // Kazde pnacze rozpoczyna wzrost po przypisanym mu opoznieniu.
                if (activationTimer >= vineDelays[i])
                {
                    vineProgress[i] += dt / growthDuration;
                }
            }
            else
            {
                // Po dezaktywacji pnacza stopniowo skracaja sie od swoich koncow.
                vineProgress[i] -= dt / growthDuration;
            }

            // Ograniczenie postepu animacji do zakresu 0-1.
            vineProgress[i] = Mathf.Clamp01(
                vineProgress[i]
            );

            UpdateVineGeometry(i);
        }

        // Licznik czasu jest zwiekszany tylko podczas aktywnego wzrostu.
        if (shouldGrow)
            activationTimer += dt;
    }

    private void UpdateVineGeometry(int index)
    {
        float progress = vineProgress[index];

        // Ukrycie pnacza, gdy jego postep animacji jest bliski zeru.
        if (progress <= 0.001f)
        {
            vines[index].positionCount = 0;
            return;
        }

        // Wyznaczenie liczby punktow widocznych przy aktualnym postepie wzrostu.
        float exactIndex =
            progress * (pointsPerVine - 1);

        int visiblePoints = Mathf.Clamp(
            Mathf.CeilToInt(exactIndex) + 1,
            2,
            pointsPerVine
        );

        LineRenderer line = vines[index];

        line.positionCount = visiblePoints;

        // Przekazanie do LineRenderer punktow odpowiadajacych aktualnemu fragmentowi pnacza.
        for (int j = 0; j < visiblePoints; j++)
        {
            line.SetPosition(j, paths[index][j]);
        }

        // Interpolacja ostatniego punktu zapewnia plynne zakonczenie animowanego wzrostu.
        int last = visiblePoints - 1;

        if (last > 0 && last < pointsPerVine)
        {
            int previous = last - 1;

            Vector3 endpoint = Vector3.Lerp(
                paths[index][previous],
                paths[index][last],
                Mathf.Clamp01(exactIndex - previous)
            );

            line.SetPosition(last, endpoint);
        }
    }

    private void UpdateFireflies()
    {
        // Zabezpieczenie na wypadek, gdy tablica swietlikow nie zostala utworzona.
        if (fireflies == null)
            return;

        // Wyznaczenie najwiekszego postepu wzrostu sposrod wszystkich pnaczy.
        float totalProgress = 0f;

        for (int i = 0; i < vineProgress.Length; i++)
        {
            totalProgress = Mathf.Max(
                totalProgress,
                vineProgress[i]
            );
        }

        for (int i = 0; i < fireflies.Length; i++)
        {
            // Kat okresla ruch swietlika po orbicie wokol drzewa.
            float angle =
                fireflyOffsets[i]
                + Time.time * fireflySpeed
                + Mathf.Sin(
                    Time.time * 0.8f + fireflyPhases[i]
                ) * 0.35f;

            // Niewielkie odchylenia w osiach X i Z nadaja ruchowi naturalny charakter.
            float wobbleX =
                Mathf.Sin(
                    Time.time * 1.5f + fireflyPhases[i]
                ) * fireflyWobble;

            float wobbleZ =
                Mathf.Cos(
                    Time.time * 1.2f + fireflyPhases[i]
                ) * fireflyWobble;

            // Obliczenie poziomego polozenia swietlika na orbicie.
            float x =
                Mathf.Cos(angle) * fireflyRadius + wobbleX;

            float z =
                Mathf.Sin(angle) * fireflyRadius + wobbleZ;

            // Funkcja Repeat zapewnia cykliczny ruch swietlikow w zakresie wysokosci drzewa.
            float y =
                Mathf.Repeat(
                    fireflyPhases[i] * 0.2f
                    + Time.time * 0.25f
                    + i * 0.173f,
                    1f
                ) * fireflyHeight;

            fireflies[i].localPosition =
                new Vector3(x, y, z);

            // Pulsowanie skali oraz uzaleznienie widocznosci od postepu wzrostu pnaczy.
            float pulse =
                0.7f
                + 0.3f * Mathf.Sin(
                    Time.time * 4f + fireflyPhases[i]
                );

            float scale =
                fireflySize * pulse * totalProgress;

            fireflies[i].localScale =
                Vector3.one * scale;
        }
    }

    private void OnDestroy()
    {
        // Usuniecie grupy swietlikow razem z jej obiektami podrzednymi.
        if (fireflyRoot != null)
            Destroy(fireflyRoot.gameObject);
    }
}
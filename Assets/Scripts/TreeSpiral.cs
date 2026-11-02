using UnityEngine;

public class MagicTreeVines : MonoBehaviour
{
    [Header("Materialy")]
    [SerializeField] private Material vineMaterial;
    [SerializeField] private Material fireflyMaterial;

    [Header("Aktywacja")]
    [SerializeField] private Transform player;
    [SerializeField] private float activationDistance = 5f;
    [SerializeField] private bool alwaysActive = true;

    [Header("Pnacza")]
    [SerializeField] private int vineCount = 5;
    [SerializeField] private int pointsPerVine = 100;
    [SerializeField] private float vineHeight = 4.5f;
    [SerializeField] private float trunkRadius = 0.65f;
    [SerializeField] private float vineWidth = 0.045f;
    [SerializeField] private float spiralTurns = 1.5f;
    [SerializeField] private float irregularity = 0.18f;
    [SerializeField] private float sway = 0.06f;

    [Header("Wyrastanie i zanikanie")]
    [SerializeField] private float growthDuration = 3f;
    [SerializeField] private float delayBetweenVines = 0.45f;

    [Header("Swietliki")]
    [SerializeField] private int fireflyCount = 24;
    [SerializeField] private float fireflyRadius = 1.5f;
    [SerializeField] private float fireflyHeight = 4.5f;
    [SerializeField] private float fireflySize = 0.055f;
    [SerializeField] private float fireflySpeed = 0.7f;
    [SerializeField] private float fireflyWobble = 0.18f;

    private LineRenderer[] vines;
    private Vector3[][] paths;
    private float[] vineProgress;
    private float[] vineDelays;

    private Transform fireflyRoot;
    private Transform[] fireflies;
    private float[] fireflyOffsets;
    private float[] fireflyPhases;

    private float activationTimer;
    private bool wasActive;

    private void Start()
    {
        if (vineMaterial == null)
        {
            Debug.LogError(
                "MagicTreeVines: przypisz Vine Material!",
                this
            );

            enabled = false;
            return;
        }

        vineCount = Mathf.Max(1, vineCount);
        pointsPerVine = Mathf.Max(10, pointsPerVine);
        fireflyCount = Mathf.Max(0, fireflyCount);
        growthDuration = Mathf.Max(0.1f, growthDuration);

        CreateVines();
        CreateFireflies();
    }

    private void CreateVines()
    {
        vines = new LineRenderer[vineCount];
        paths = new Vector3[vineCount][];
        vineProgress = new float[vineCount];
        vineDelays = new float[vineCount];

        for (int i = 0; i < vineCount; i++)
        {
            GameObject obj = new GameObject(
                "Magic Vine " + i
            );

            obj.transform.SetParent(transform, false);

            LineRenderer line =
                obj.AddComponent<LineRenderer>();

            line.useWorldSpace = false;
            line.sharedMaterial = vineMaterial;

            line.startWidth = vineWidth;
            line.endWidth = vineWidth * 0.25f;

            line.numCapVertices = 4;
            line.numCornerVertices = 4;
            line.positionCount = 0;

            line.shadowCastingMode =
                UnityEngine.Rendering.ShadowCastingMode.Off;

            line.receiveShadows = false;

            vines[i] = line;
            paths[i] = GenerateVinePath(i);
            vineDelays[i] = i * delayBetweenVines;
        }
    }

    private Vector3[] GenerateVinePath(int index)
    {
        Vector3[] points = new Vector3[pointsPerVine];

        float startAngle =
            index / (float)vineCount * Mathf.PI * 2f
            + Random.Range(-0.35f, 0.35f);

        float turns =
            spiralTurns * Random.Range(0.7f, 1.3f);

        float phase1 = Random.Range(0f, 10f);
        float phase2 = Random.Range(0f, 10f);

        for (int i = 0; i < pointsPerVine; i++)
        {
            float t = i / (float)(pointsPerVine - 1);

            float angle =
                startAngle + t * turns * Mathf.PI * 2f;

            float variation =
                Mathf.Sin(t * 17f + phase1) * irregularity
                + Mathf.Sin(t * 31f + phase2)
                * irregularity * 0.4f;

            float r = trunkRadius + variation;

            float x = Mathf.Cos(angle) * r;
            float z = Mathf.Sin(angle) * r;

            x += Mathf.Sin(t * 12f + phase2) * sway;
            z += Mathf.Cos(t * 15f + phase1) * sway;

            float y =
                vineHeight * t
                + Mathf.Sin(t * Mathf.PI * 2f + phase1) * 0.08f;

            points[i] = new Vector3(x, y, z);
        }

        return points;
    }

    private void CreateFireflies()
    {
        fireflyRoot = new GameObject(
            "Magic Fireflies"
        ).transform;

        fireflyRoot.SetParent(transform, false);
        fireflyRoot.localPosition = Vector3.zero;

        fireflies = new Transform[fireflyCount];
        fireflyOffsets = new float[fireflyCount];
        fireflyPhases = new float[fireflyCount];

        for (int i = 0; i < fireflyCount; i++)
        {
            GameObject obj = GameObject.CreatePrimitive(
                PrimitiveType.Sphere
            );

            obj.name = "Firefly " + i;
            obj.transform.SetParent(fireflyRoot, false);

            Collider col = obj.GetComponent<Collider>();

            if (col != null)
                Destroy(col);

            Renderer rend = obj.GetComponent<Renderer>();

            // Mozna przypisac osobny material swietlikow.
            // Jesli go nie ma, wykorzystujemy material pnaczy.
            rend.sharedMaterial =
                fireflyMaterial != null
                ? fireflyMaterial
                : vineMaterial;

            rend.shadowCastingMode =
                UnityEngine.Rendering.ShadowCastingMode.Off;

            rend.receiveShadows = false;

            fireflies[i] = obj.transform;

            fireflyOffsets[i] =
                Random.Range(0f, Mathf.PI * 2f);

            fireflyPhases[i] =
                Random.Range(0f, Mathf.PI * 2f);

            obj.transform.localScale = Vector3.zero;
        }
    }

    private void Update()
    {
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

        if (shouldBeActive && !wasActive)
        {
            // Nowy cykl wzrostu.
            // Jesli pnacza jeszcze zanikaja, moga znowu rosnac
            // od aktualnej dlugosci.
            activationTimer = 0f;
        }

        wasActive = shouldBeActive;

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
                if (activationTimer >= vineDelays[i])
                {
                    vineProgress[i] += dt / growthDuration;
                }
            }
            else
            {
                // Pnacza cofaja sie stopniowo od koncowek.
                vineProgress[i] -= dt / growthDuration;
            }

            vineProgress[i] = Mathf.Clamp01(
                vineProgress[i]
            );

            UpdateVineGeometry(i);
        }

        if (shouldGrow)
            activationTimer += dt;
    }

    private void UpdateVineGeometry(int index)
    {
        float progress = vineProgress[index];

        if (progress <= 0.001f)
        {
            vines[index].positionCount = 0;
            return;
        }

        float exactIndex =
            progress * (pointsPerVine - 1);

        int visiblePoints = Mathf.Clamp(
            Mathf.CeilToInt(exactIndex) + 1,
            2,
            pointsPerVine
        );

        LineRenderer line = vines[index];

        line.positionCount = visiblePoints;

        for (int j = 0; j < visiblePoints; j++)
        {
            line.SetPosition(j, paths[index][j]);
        }

        // Ostatni punkt porusza sie plynnie podczas wzrostu
        // i cofania pnacza.
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
        if (fireflies == null)
            return;

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
            float angle =
                fireflyOffsets[i]
                + Time.time * fireflySpeed
                + Mathf.Sin(
                    Time.time * 0.8f + fireflyPhases[i]
                ) * 0.35f;

            float wobbleX =
                Mathf.Sin(
                    Time.time * 1.5f + fireflyPhases[i]
                ) * fireflyWobble;

            float wobbleZ =
                Mathf.Cos(
                    Time.time * 1.2f + fireflyPhases[i]
                ) * fireflyWobble;

            float x =
                Mathf.Cos(angle) * fireflyRadius + wobbleX;

            float z =
                Mathf.Sin(angle) * fireflyRadius + wobbleZ;

            float y =
                Mathf.Repeat(
                    fireflyPhases[i] * 0.2f
                    + Time.time * 0.25f
                    + i * 0.173f,
                    1f
                ) * fireflyHeight;

            fireflies[i].localPosition =
                new Vector3(x, y, z);

            // Swietliki delikatnie pulsuj?.
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
        if (fireflyRoot != null)
            Destroy(fireflyRoot.gameObject);
    }
}
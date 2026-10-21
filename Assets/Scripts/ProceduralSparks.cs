
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class ProceduralCrystalSparks : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private Transform crystal;
    [SerializeField] private Material sparkMaterial;

    [Header("Spark Settings")]
    [SerializeField, Range(5, 100)] private int sparkCount = 71;
    [SerializeField, Min(0.1f)] private float orbitRadius = 1.55f;
    [SerializeField, Min(0.01f)] private float sparkSize = 0.06f;
    [SerializeField, Min(0.1f)] private float lifetime = 3f;

    [Header("Movement")]
    [SerializeField] private float orbitSpeed = 0.7f;
    [SerializeField] private float riseSpeed = 0.3f;
    [SerializeField] private float wobbleAmount = 0.88f;
    [SerializeField] private float wobbleSpeed = 0.5f;

    private Mesh sparkMesh;
    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;

    private Vector3[] vertices;
    private Vector2[] uvs;
    private int[] triangles;
    private Color[] colors;

    private Spark[] sparks;

    private class Spark
    {
        public float angle;
        public float height;
        public float age;
        public float lifetime;
        public float radius;
        public float size;
        public float phase;
        public float speed;
    }

    private void Start()
    {
        if (crystal == null)
            crystal = transform.parent != null ? transform.parent : transform;

        meshFilter = GetComponent<MeshFilter>();
        meshRenderer = GetComponent<MeshRenderer>();

        if (sparkMaterial != null)
            meshRenderer.sharedMaterial = sparkMaterial;
        else
            Debug.LogError(
                "Przypisz materia? M_ProceduralSpark!",
                this
            );

        CreateSparks();
    }

    private void CreateSparks()
    {
        int count = sparkCount;

        vertices = new Vector3[count * 4];
        uvs = new Vector2[count * 4];
        colors = new Color[count * 4];
        triangles = new int[count * 6];
        sparks = new Spark[count];

        for (int i = 0; i < count; i++)
        {
            int v = i * 4;
            int t = i * 6;

            // Quad: cztery wierzcholki jednej iskry.
            vertices[v] = Vector3.zero;
            vertices[v + 1] = Vector3.zero;
            vertices[v + 2] = Vector3.zero;
            vertices[v + 3] = Vector3.zero;

            uvs[v] = new Vector2(0, 0);
            uvs[v + 1] = new Vector2(1, 0);
            uvs[v + 2] = new Vector2(1, 1);
            uvs[v + 3] = new Vector2(0, 1);

            triangles[t] = v;
            triangles[t + 1] = v + 2;
            triangles[t + 2] = v + 1;
            triangles[t + 3] = v;
            triangles[t + 4] = v + 3;
            triangles[t + 5] = v + 2;

            sparks[i] = new Spark();
            ResetSpark(sparks[i], true);
        }

        sparkMesh = new Mesh();
        sparkMesh.name = "Procedural Crystal Sparks";
        sparkMesh.MarkDynamic();

        sparkMesh.vertices = vertices;
        sparkMesh.uv = uvs;
        sparkMesh.triangles = triangles;
        sparkMesh.colors = colors;

        meshFilter.sharedMesh = sparkMesh;
    }

    private void ResetSpark(Spark spark, bool randomHeight)
    {
        spark.angle = Random.Range(0f, Mathf.PI * 2f);
        spark.radius = Random.Range(orbitRadius * 0.45f, orbitRadius);
        spark.age = randomHeight ? Random.Range(0f, lifetime) : 0f;
        spark.lifetime = lifetime * Random.Range(0.7f, 1.3f);
        spark.size = sparkSize * Random.Range(0.5f, 1.4f);
        spark.phase = Random.Range(0f, Mathf.PI * 2f);
        spark.speed = Random.Range(0.7f, 1.3f);
        spark.height = randomHeight
            ? Random.Range(-orbitRadius * 0.5f, orbitRadius * 0.5f)
            : -orbitRadius * 0.5f;
    }

    private void LateUpdate()
    {
        if (sparkMesh == null || crystal == null)
            return;

        float dt = Time.deltaTime;

        for (int i = 0; i < sparks.Length; i++)
        {
            Spark spark = sparks[i];
            spark.age += dt;

            if (spark.age >= spark.lifetime)
                ResetSpark(spark, false);

            spark.angle += orbitSpeed * spark.speed * dt;
            spark.height += riseSpeed * dt;

            if (spark.height > orbitRadius * 0.5f)
                spark.height = -orbitRadius * 0.5f;

            float wobbleX = Mathf.Sin(
                Time.time * wobbleSpeed + spark.phase
            ) * wobbleAmount;

            float wobbleZ = Mathf.Cos(
                Time.time * wobbleSpeed * 0.8f + spark.phase
            ) * wobbleAmount;

            Vector3 localPosition = new Vector3(
                Mathf.Cos(spark.angle) * spark.radius + wobbleX,
                spark.height,
                Mathf.Sin(spark.angle) * spark.radius + wobbleZ
            );

            // Pozycja iskry wzgl?dem kryszta?u, tak?e gdy kryszta? lewituje.
            Vector3 worldPosition = crystal.TransformPoint(localPosition);

            // Iskry s? billboardami skierowanymi w stron? kamery.
            Camera cam = Camera.main;
            Vector3 right = cam != null
                ? cam.transform.right
                : Vector3.right;
            Vector3 up = cam != null
                ? cam.transform.up
                : Vector3.up;

            float size = spark.size;

            int v = i * 4;
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

            float normalizedAge = spark.age / spark.lifetime;
            float fadeIn = Mathf.Clamp01(normalizedAge * 5f);
            float fadeOut = Mathf.Clamp01((1f - normalizedAge) * 4f);
            float pulse = 0.75f + 0.25f * Mathf.Sin(
                Time.time * 5f + spark.phase
            );

            float alpha = fadeIn * fadeOut * pulse;
            Color sparkColor = new Color(1f, 1f, 1f, alpha);

            colors[v] = sparkColor;
            colors[v + 1] = sparkColor;
            colors[v + 2] = sparkColor;
            colors[v + 3] = sparkColor;
        }

        sparkMesh.vertices = vertices;
        sparkMesh.colors = colors;
        sparkMesh.RecalculateBounds();
    }

    private void OnDestroy()
    {
        if (sparkMesh != null)
            Destroy(sparkMesh);
    }
}

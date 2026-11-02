
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class MagicalGrassGenerator : MonoBehaviour
{
    [Header("Terrain")]
    public Terrain terrain;

    [Header("Grass Density")]
    [Min(0.1f)] public float density = 1.5f;
    [Min(1f)] public float chunkSize = 10f;

    [Header("Blade Shape")]
    [Min(0.1f)] public float minHeight = 0.35f;
    [Min(0.1f)] public float maxHeight = 0.8f;
    [Min(0.01f)] public float bladeWidth = 0.09f;
    [Range(0f, 1f)] public float curvature = 0.3f;

    [Header("Variation")]
    [Range(0f, 1f)] public float heightRandomness = 0.4f;
    [Range(0f, 1f)] public float widthRandomness = 0.3f;
    public int seed = 12345;

    [Header("Material")]
    public Material grassMaterial;

    private readonly List<GameObject> chunks = new();

    [ContextMenu("Generate Magical Grass")]
    public void GenerateGrass()
    {
        ClearGrass();

        if (terrain == null || terrain.terrainData == null)
        {
            Debug.LogError("Magical Grass: Assign Terrain!");
            return;
        }

        TerrainData data = terrain.terrainData;
        Vector3 size = data.size;

        System.Random random = new System.Random(seed);

        int countX = Mathf.CeilToInt(size.x / chunkSize);
        int countZ = Mathf.CeilToInt(size.z / chunkSize);

        for (int x = 0; x < countX; x++)
        {
            for (int z = 0; z < countZ; z++)
            {
                GenerateChunk(x, z, random);
            }
        }

        Debug.Log("Magical Grass generated!");
    }

    void GenerateChunk(int chunkX, int chunkZ, System.Random random)
    {
        TerrainData data = terrain.terrainData;
        Vector3 size = data.size;

        float startX = chunkX * chunkSize;
        float startZ = chunkZ * chunkSize;

        float endX = Mathf.Min(startX + chunkSize, size.x);
        float endZ = Mathf.Min(startZ + chunkSize, size.z);

        float area = (endX - startX) * (endZ - startZ);
        int bladeCount = Mathf.RoundToInt(area * density);

        List<Vector3> vertices = new();
        List<Vector2> uvs = new();
        List<Color> colors = new();
        List<int> triangles = new();

        for (int i = 0; i < bladeCount; i++)
        {
            float x = Mathf.Lerp(startX, endX, (float)random.NextDouble());
            float z = Mathf.Lerp(startZ, endZ, (float)random.NextDouble());

            float u = x / size.x;
            float v = z / size.z;

            float y = data.GetInterpolatedHeight(u, v);
            Vector3 normal = data.GetInterpolatedNormal(u, v);

            Vector3 worldPosition = terrain.transform.TransformPoint(
                new Vector3(x, y, z));

            Vector3 worldNormal = terrain.transform
                .TransformDirection(normal).normalized;

            float randomHeight = Mathf.Lerp(
                minHeight, maxHeight, (float)random.NextDouble());

            randomHeight *= Mathf.Lerp(
                1f - heightRandomness, 1f + heightRandomness,
                (float)random.NextDouble());

            float width = bladeWidth * Mathf.Lerp(
                1f - widthRandomness, 1f + widthRandomness,
                (float)random.NextDouble());

            float angle = (float)random.NextDouble() * 360f;

            Vector3 direction = Quaternion.AngleAxis(angle, worldNormal)
                * Vector3.forward;

            direction = Vector3.ProjectOnPlane(
                direction, worldNormal).normalized;

            // Two intersecting planes give the blade a 3D appearance.
            AddBladePlane(
                vertices, uvs, colors, triangles,
                worldPosition, worldNormal, direction,
                randomHeight, width, random);

            Vector3 secondDirection = Vector3.Cross(
                worldNormal, direction).normalized;

            AddBladePlane(
                vertices, uvs, colors, triangles,
                worldPosition, worldNormal, secondDirection,
                randomHeight, width, random);
        }

        if (vertices.Count == 0)
            return;

        Mesh mesh = new Mesh();
        mesh.name = $"MagicalGrass_{chunkX}_{chunkZ}";

        if (vertices.Count > 65535)
            mesh.indexFormat = IndexFormat.UInt32;

        mesh.SetVertices(vertices);
        mesh.SetUVs(0, uvs);
        mesh.SetColors(colors);
        mesh.SetTriangles(triangles, 0);
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();

        GameObject chunk = new GameObject(mesh.name);
        chunk.transform.SetParent(transform, false);

        MeshFilter filter = chunk.AddComponent<MeshFilter>();
        MeshRenderer renderer = chunk.AddComponent<MeshRenderer>();

        filter.sharedMesh = mesh;
        renderer.sharedMaterial = grassMaterial;

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
        const int segments = 3;

        Vector3 right = Vector3.Cross(normal, direction).normalized;

        float randomBend = (float)random.NextDouble() * 0.5f + 0.75f;

        Vector3 bendDirection = direction * curvature * randomBend;

        int startIndex = vertices.Count;

        for (int i = 0; i <= segments; i++)
        {
            float t = (float)i / segments;

            float currentWidth = width * (1f - t * 0.9f);

            Vector3 center = position
                + normal * (height * t)
                + bendDirection * (height * t * t);

            Vector3 left = center - right * currentWidth * 0.5f;
            Vector3 rightPoint = center + right * currentWidth * 0.5f;

            vertices.Add(transform.InverseTransformPoint(left));
            vertices.Add(transform.InverseTransformPoint(rightPoint));

            uvs.Add(new Vector2(0f, t));
            uvs.Add(new Vector2(1f, t));

            // Random blade color variation for the future shader.
            Color variation = new Color(
                random.Next(80, 121) / 100f,
                random.Next(80, 121) / 100f,
                random.Next(80, 121) / 100f,
                1f);

            colors.Add(variation);
            colors.Add(variation);
        }

        for (int i = 0; i < segments; i++)
        {
            int a = startIndex + i * 2;
            int b = a + 1;
            int c = a + 2;
            int d = a + 3;

            triangles.Add(a);
            triangles.Add(c);
            triangles.Add(b);

            triangles.Add(b);
            triangles.Add(c);
            triangles.Add(d);
        }
    }


    [ContextMenu("Clear Magical Grass")]
    public void ClearGrass()
    {
        // Usuwamy wszystkie obiekty potomne generatora.
        for (int i = transform.childCount - 1; i >= 0; i--)
        {
            Transform child = transform.GetChild(i);

            MeshFilter filter = child.GetComponent<MeshFilter>();

            if (filter != null && filter.sharedMesh != null)
            {
                Mesh mesh = filter.sharedMesh;
                filter.sharedMesh = null;

                if (Application.isPlaying)
                    Destroy(mesh);
                else
                    DestroyImmediate(mesh);
            }

            if (Application.isPlaying)
                Destroy(child.gameObject);
            else
                DestroyImmediate(child.gameObject);
        }

        chunks.Clear();

        Debug.Log("Magical Grass cleared!");
    }
}
#if UNITY_EDITOR
    [UnityEditor.CustomEditor(typeof(MagicalGrassGenerator))]
public class MagicalGrassGeneratorEditor : UnityEditor.Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        MagicalGrassGenerator generator =
            (MagicalGrassGenerator)target;

        GUILayout.Space(10);

        if (GUILayout.Button("GENERATE MAGICAL GRASS", GUILayout.Height(35)))
        {
            generator.GenerateGrass();
        }

        if (GUILayout.Button("CLEAR MAGICAL GRASS", GUILayout.Height(30)))
        {
            generator.ClearGrass();
        }
    }
}
#endif

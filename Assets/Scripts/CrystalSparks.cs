
using UnityEngine;

public class MagicSpiral : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private Transform player;
    [SerializeField] private Material particleMaterial;

    [Header("Spiral")]
    [SerializeField, Min(1)] private int particleCount = 60;
    [SerializeField, Min(0.1f)] private float radius = 1.2f;
    [SerializeField, Min(0.5f)] private float height = 5f;
    [SerializeField, Min(0.1f)] private float rotationSpeed = 2f;
    [SerializeField, Min(0.1f)] private float upwardSpeed = 1.5f;
    [SerializeField, Min(0.01f)] private float particleSize = 0.07f;

    [Header("Activation")]
    [SerializeField, Min(0.1f)] private float activationDistance = 5f;
    [SerializeField] private bool alwaysActive = false;

    private Transform particleRoot;
    private Transform[] particles;
    private float[] offsets;
    private bool isActive;

    private void Start()
    {
        if (particleMaterial == null)
        {
            Debug.LogError(
                "MagicTreeSpiral: przypisz materia? Particle Material.",
                this
            );
            enabled = false;
            return;
        }

        particleRoot = new GameObject("Generated Magic Spiral").transform;
        particleRoot.SetParent(transform, false);
        particleRoot.localPosition = Vector3.zero;

        particles = new Transform[particleCount];
        offsets = new float[particleCount];

        for (int i = 0; i < particleCount; i++)
        {
            GameObject particle = GameObject.CreatePrimitive(
                PrimitiveType.Sphere
            );

            particle.name = "Magic Particle " + i;
            particle.transform.SetParent(particleRoot, false);

            Collider particleCollider =
                particle.GetComponent<Collider>();

            if (particleCollider != null)
                Destroy(particleCollider);

            Renderer particleRenderer =
                particle.GetComponent<Renderer>();

            particleRenderer.sharedMaterial = particleMaterial;
            particleRenderer.shadowCastingMode =
                UnityEngine.Rendering.ShadowCastingMode.Off;
            particleRenderer.receiveShadows = false;

            particles[i] = particle.transform;
            offsets[i] = (float)i / particleCount;

            particle.transform.localScale =
                Vector3.one * particleSize;
        }

        SetParticlesVisible(false);
    }

    private void Update()
    {
        if (player == null && !alwaysActive)
            return;

        bool shouldBeActive = alwaysActive;

        if (player != null)
        {
            float distance = Vector3.Distance(
                player.position,
                transform.position
            );

            shouldBeActive |= distance <= activationDistance;
        }

        if (shouldBeActive != isActive)
        {
            isActive = shouldBeActive;
            SetParticlesVisible(isActive);
        }

        if (!isActive)
            return;

        for (int i = 0; i < particles.Length; i++)
        {
            float progress = Mathf.Repeat(
                offsets[i] + Time.time * upwardSpeed / height,
                1f
            );

            float angle =
                offsets[i] * Mathf.PI * 2f
                + Time.time * rotationSpeed;

            float x = Mathf.Cos(angle) * radius;
            float z = Mathf.Sin(angle) * radius;
            float y = progress * height;

            particles[i].localPosition = new Vector3(x, y, z);

            float pulse = 0.75f +
                0.25f * Mathf.Sin(Time.time * 4f + i);

            particles[i].localScale =
                Vector3.one * particleSize * pulse;
        }
    }

    private void SetParticlesVisible(bool visible)
    {
        if (particles == null)
            return;

        foreach (Transform particle in particles)
        {
            if (particle != null)
                particle.gameObject.SetActive(visible);
        }
    }

    private void OnDestroy()
    {
        if (particleRoot != null)
            Destroy(particleRoot.gameObject);
    }
}

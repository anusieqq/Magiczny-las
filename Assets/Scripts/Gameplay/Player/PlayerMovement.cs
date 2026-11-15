using UnityEngine;
using UnityEngine.InputSystem;

/// <summary>
/// Obsluguje poruszanie sie gracza w trybie pierwszoosobowym,
/// sterowanie kamera za pomoca myszy oraz obsluge kursora.
/// </summary>
[RequireComponent(typeof(CharacterController))]
public class PlayerMovement : MonoBehaviour
{
    [Header("Movement")]
    [SerializeField] private float moveSpeed = 5f;
    [SerializeField] private float gravity = -9.81f;

    [Header("Mouse Look")]
    [SerializeField] private Transform cameraTransform;
    [SerializeField] private float mouseSensitivity = 0.1f;
    [SerializeField] private float maxLookAngle = 85f;

    // Referencja do komponentu odpowiedzialnego za ruch i kolizje postaci.
    private CharacterController characterController;

    // Aktualna predkosc pionowa uwzgledniajaca dzialanie grawitacji.
    private float verticalVelocity;

    // Aktualny kat pochylenia kamery w osi pionowej.
    private float cameraPitch;

    private void Awake()
    {
        // Pobranie komponentu CharacterController z tego samego obiektu.
        characterController = GetComponent<CharacterController>();

        // Jesli kamera nie zostala przypisana w Inspectorze,
        // skrypt probuje znalezc ja w obiektach podrzednych gracza.
        if (cameraTransform == null)
        {
            Camera childCamera = GetComponentInChildren<Camera>();

            if (childCamera != null)
                cameraTransform = childCamera.transform;
        }
    }

    private void Start()
    {
        // Kamera jest wymagana do obslugi widoku pierwszoosobowego.
        if (cameraTransform == null)
        {
            Debug.LogError(
                "PlayerMovement: assign a camera to Camera Transform.",
                this
            );

            enabled = false;
            return;
        }

        // Zablokowanie kursora na srodku ekranu i ukrycie go podczas rozgrywki.
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;

        // Odczyt poczatkowego kata kamery, aby zachowac jej ustawienie poczatkowe.
        cameraPitch = cameraTransform.localEulerAngles.x;

        // Konwersja kata z zakresu 0-360 do zakresu -180-180.
        if (cameraPitch > 180f)
            cameraPitch -= 360f;
    }

    private void Update()
    {
        // Brak aktywnej klawiatury oznacza brak mozliwosci odczytu sterowania.
        if (Keyboard.current == null)
            return;

        // Obsluga odblokowania i ponownego blokowania kursora.
        HandleCursor();

        // Sterowanie postacia jest mozliwe tylko przy zablokowanym kursorze.
        if (Cursor.lockState != CursorLockMode.Locked)
            return;

        // Odczyt ruchu myszy i aktualizacja kierunku patrzenia.
        if (Mouse.current != null)
            LookAround();

        // Aktualizacja ruchu postaci.
        Move();
    }

    private void LookAround()
    {
        // Odczyt przesuniecia myszy od ostatniej klatki.
        Vector2 mouseDelta = Mouse.current.delta.ReadValue();

        // Przeliczenie ruchu myszy na zmiane katow obrotu.
        float mouseX = mouseDelta.x * mouseSensitivity;
        float mouseY = mouseDelta.y * mouseSensitivity;

        // Obracanie calej postaci wokol osi Y odpowiada za rozgladanie sie w poziomie.
        transform.Rotate(Vector3.up * mouseX);

        // Zmiana pochylenia kamery w pionie.
        cameraPitch -= mouseY;

        // Ograniczenie kata patrzenia zapobiega nadmiernemu obracaniu kamery.
        cameraPitch = Mathf.Clamp(
            cameraPitch,
            -maxLookAngle,
            maxLookAngle
        );

        // Pochylenie jest przypisywane tylko kamerze, bez obracania calej postaci.
        cameraTransform.localRotation =
            Quaternion.Euler(cameraPitch, 0f, 0f);
    }

    private void Move()
    {
        // Wektor wejscia przechowuje kierunek ruchu na plaszczyznie poziomej.
        Vector2 input = Vector2.zero;

        // Odczyt kierunku ruchu z klawiszy WASD.
        if (Keyboard.current.wKey.isPressed)
            input.y += 1f;

        if (Keyboard.current.sKey.isPressed)
            input.y -= 1f;

        if (Keyboard.current.dKey.isPressed)
            input.x += 1f;

        if (Keyboard.current.aKey.isPressed)
            input.x -= 1f;

        // Normalizacja ogranicza dlugosc wektora, dzieki czemu ruch po przekatnej
        // nie jest szybszy od ruchu w pojedynczym kierunku.
        input = Vector2.ClampMagnitude(input, 1f);

        // Przeliczenie kierunku sterowania na kierunek wzgledem obrotu gracza.
        Vector3 direction =
            transform.right * input.x +
            transform.forward * input.y;

        // Utrzymanie niewielkiej predkosci skierowanej w dol,
        // gdy postac znajduje sie na podlozu.
        if (characterController.isGrounded && verticalVelocity < 0f)
            verticalVelocity = -2f;

        // Aktualizacja predkosci pionowej na podstawie grawitacji.
        verticalVelocity += gravity * Time.deltaTime;

        // Polaczenie ruchu poziomego z ruchem pionowym wynikajacym z grawitacji.
        Vector3 velocity =
            direction * moveSpeed +
            Vector3.up * verticalVelocity;

        // Przesuniecie postaci z uwzglednieniem kolizji CharacterController.
        characterController.Move(velocity * Time.deltaTime);
    }

    private void HandleCursor()
    {
        // Nacisniecie Escape odblokowuje kursor i przywraca jego widocznosc.
        if (Keyboard.current.escapeKey.wasPressedThisFrame)
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }

        // Klikniecie lewym przyciskiem myszy ponownie blokuje kursor,
        // co pozwala wznowic sterowanie kamera.
        if (Mouse.current != null &&
            Mouse.current.leftButton.wasPressedThisFrame &&
            Cursor.lockState != CursorLockMode.Locked)
        {
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }
    }

    private void OnDisable()
    {
        // Przy wylaczeniu skryptu kursor zostaje odblokowany,
        // aby nie pozostal ukryty poza aktywna rozgrywka.
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
    }
}